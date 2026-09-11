<#
.SYNOPSIS
    Compila o Flutter Web e (re)inicia o container que serve o app.

.DESCRIPTION
    O app web é servido como build estático por um Nginx. Reiniciar o container
    sozinho NÃO aplica alterações de código — é preciso recompilar. Este script
    faz os dois passos.

    Usa a imagem oficial do Flutter via Docker, então não é necessário ter o
    Flutter SDK instalado na máquina.

.PARAMETER Api
    URL da API consumida pelo app. Quando omitida, o app descobre o backend a
    partir do endereço em que a página foi aberta (mesmo host, porta 8000).
    Isso faz um único build funcionar em http://localhost:8080, no navegador do
    emulador Android (http://10.0.2.2:8080) e em outro aparelho da rede local.
    Informe explicitamente apenas para apontar para outro ambiente.

.PARAMETER Port
    Porta em que o app será publicado. Padrão: 8080

.PARAMETER Logs
    Liga os logs de rede no console do navegador (útil para diagnóstico).

.PARAMETER GoogleClientId
    Client ID web do "Entrar com o Google" (Google Cloud > Credenciais). Quando
    omitido, o script usa a variável de ambiente GOOGLE_WEB_CLIENT_ID. Sem
    nenhum dos dois, o botão do Google não aparece no app — o login por e-mail
    e senha continua funcionando.

.PARAMETER NoBuild
    Só reinicia o container, sem recompilar (serve o build atual).

.PARAMETER Pwa
    Gera o service worker (modo produção/offline). Desligado por padrão: em
    desenvolvimento o service worker serve o build antigo mesmo após recompilar,
    e nem o Ctrl+Shift+R resolve — ele intercepta as requisições.

.EXAMPLE
    .\scripts\web.ps1
    Recompila e reinicia em http://localhost:8080

.EXAMPLE
    .\scripts\web.ps1 -Logs
    Recompila com logs de rede ligados

.EXAMPLE
    .\scripts\web.ps1 -NoBuild
    Apenas reinicia o container
#>
[CmdletBinding()]
param(
    [string]$Api = "",
    [string]$GoogleClientId = $env:GOOGLE_WEB_CLIENT_ID,
    [int]$Port = 8080,
    [switch]$Logs,
    [switch]$NoBuild,
    [switch]$Pwa
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$frontend = $root
$nginxConf = Join-Path $root "docker\nginx\flutter-web.conf"
$container = "sua_barbearia_web"
$image = "ghcr.io/cirruslabs/flutter:stable"
$cache = "sua_barbearia_pub_cache"

if (-not (Test-Path (Join-Path $frontend "pubspec.yaml"))) {
    throw "pubspec.yaml nao encontrado em $frontend - rode o script de dentro do repositorio do app"
}

if (-not $NoBuild) {
    if ($Api) {
        Write-Host "==> Compilando o Flutter Web (API: $Api)..." -ForegroundColor Cyan
    } else {
        Write-Host "==> Compilando o Flutter Web (API: mesmo host, porta 8000)..." -ForegroundColor Cyan
    }

    docker volume create $cache | Out-Null

    # --- Build limpo quando as dependências mudam ---------------------------
    # O Flutter gera o registrador de plugins web a partir de estado guardado
    # em `.dart_tool`. Esse cache já ficou desatualizado depois de adicionar um
    # plugin: o build saiu sem o `image_picker` registrado e o botão de enviar
    # a logo não abria nada — sem erro, sem aviso.
    #
    # Comparar o `pubspec.yaml` com o do último build custa nada e evita
    # exatamente essa classe de falha silenciosa.
    $stamp = Join-Path $frontend "build\.pubspec-hash"
    $pubspecHash = (Get-FileHash (Join-Path $frontend "pubspec.yaml") -Algorithm MD5).Hash
    $anterior = if (Test-Path $stamp) { Get-Content $stamp -Raw } else { "" }

    if ($anterior.Trim() -ne $pubspecHash) {
        Write-Host "    dependencias mudaram: limpando o build" -ForegroundColor DarkGray
        docker run --rm -v "${frontend}:/app" -v "${cache}:/root/.pub-cache" `
            -w /app $image flutter clean | Out-Null
    }

    # Sem `-Api` nenhum define é injetado: o AppConfig deriva o host da página,
    # e o mesmo build serve localhost, o emulador e outros aparelhos da rede.
    $defines = ""
    if ($Api) { $defines = "--dart-define=API_BASE_URL=$Api" }
    if ($Logs) {
        $defines += " --dart-define=ENABLE_NETWORK_LOGS=true"
        Write-Host "    logs de rede: ligados" -ForegroundColor DarkGray
    }
    if ($GoogleClientId) {
        $defines += " --dart-define=GOOGLE_WEB_CLIENT_ID=$GoogleClientId"
        Write-Host "    entrar com o Google: ligado" -ForegroundColor DarkGray
    } else {
        Write-Host "    entrar com o Google: desligado (informe -GoogleClientId)" -ForegroundColor DarkGray
    }
    if (-not $Pwa) {
        # Sem service worker: garante que o navegador sempre pegue o build novo.
        $defines += " --pwa-strategy=none"
        Write-Host "    service worker: desligado (evita servir build antigo)" -ForegroundColor DarkGray
    }

    # A fonte de ícones vai inteira, sem tree-shaking.
    #
    # O tree-shaking gera uma fonte sob medida a cada build, com os glifos
    # remapeados. Se o navegador reaproveitar a fonte de um build anterior, os
    # códigos não batem e alguns ícones simplesmente não são desenhados — foi
    # exatamente o que aconteceu com o botão de tema, duas vezes.
    #
    # Custa ~1,6 MB em vez de ~28 KB. Em desenvolvimento na rede local o
    # tamanho não importa perto de perder tempo caçando ícone fantasma.
    $defines += " --no-tree-shake-icons"

    docker run --rm `
        -v "${frontend}:/app" `
        -v "${cache}:/root/.pub-cache" `
        -w /app $image `
        sh -c "flutter pub get && flutter build web --release $defines"

    if ($LASTEXITCODE -ne 0) { throw "Falha ao compilar o app." }

    New-Item -ItemType Directory -Force -Path (Join-Path $frontend "build") | Out-Null
    Set-Content -Path $stamp -Value $pubspecHash -NoNewline

    if (-not $Pwa) {
        # E' esta remocao que realmente desliga o service worker.
        #
        # O `--pwa-strategy=none` acima esta DEPRECADO (flutter/flutter#156910) e
        # ja nao tem efeito: o build gera o `flutter_service_worker.js` de
        # qualquer forma, e o `flutter_bootstrap.js` continua chamando
        # `navigator.serviceWorker.register(...)`. Sem o arquivo no disco o
        # register recebe 404, falha em silencio e o app roda sempre do
        # servidor.
        $staleSw = Join-Path $frontend "build\web\flutter_service_worker.js"
        if (Test-Path $staleSw) { Remove-Item $staleSw -Force }
    }

    # --- Versionamento do bundle (cache busting) ---------------------------
    # O Flutter Web NÃO coloca hash nos nomes: o build gera sempre
    # `main.dart.js` e `flutter_bootstrap.js`. Com nomes fixos, qualquer cache
    # de navegador pode continuar servindo a versão antiga do app — foi o que
    # aconteceu quando o Nginx marcava esses arquivos como `immutable`.
    #
    # A correção durável é dar a cada build uma URL própria. Como o
    # `index.html` é servido com `no-store`, ele sempre chega novo; apontá-lo
    # para uma URL versionada quebra o cache mesmo de quem já tem o arquivo
    # antigo guardado, sem precisar limpar nada à mão.
    $webDir = Join-Path $frontend "build\web"
    $mainJs = Join-Path $webDir "main.dart.js"
    $bootstrapJs = Join-Path $webDir "flutter_bootstrap.js"
    $indexHtml = Join-Path $webDir "index.html"

    if ((Test-Path $mainJs) -and (Test-Path $bootstrapJs) -and (Test-Path $indexHtml)) {
        $version = (Get-FileHash $mainJs -Algorithm MD5).Hash.Substring(0, 12).ToLower()

        # Versionar só o JS não basta: a fonte de ícones
        # (`assets/fonts/MaterialIcons-Regular.otf`) também tem nome fixo e muda
        # a cada ícone novo. Com ela presa no cache, ícones recém-adicionados
        # saem em branco enquanto os antigos aparecem — sintoma que já custou
        # caro aqui.
        #
        # Por isso a versão vai no `<base href>`: o `index.html` é `no-store`,
        # então chega sempre novo, e TODAS as URLs relativas (JS, fontes,
        # assets) passam a apontar para um prefixo inédito a cada build. O Nginx
        # remove o prefixo ao servir.
        $content = Get-Content $indexHtml -Raw
        $content = $content -replace '<base href="[^"]*">', "<base href=`"/v/$version/`">"
        Set-Content -Path $indexHtml -Value $content -NoNewline

        Write-Host "    versao do bundle: $version" -ForegroundColor DarkGray
    }
}

Write-Host "==> Reiniciando o container..." -ForegroundColor Cyan

# O `docker compose up` deste repositorio e este script servem o mesmo app na
# mesma porta, e so um pode segurar o bind. Derruba o servico do compose antes
# de subir o container de desenvolvimento, senao o `docker run` abaixo falha
# com "port is already allocated".
docker compose --project-directory $root rm -sf web 2>$null | Out-Null

docker rm -f $container 2>$null | Out-Null

docker run -d --name $container `
    -p "${Port}:80" `
    -v "${frontend}\build\web:/usr/share/nginx/html:ro" `
    -v "${nginxConf}:/etc/nginx/conf.d/default.conf:ro" `
    nginx:1.27-alpine | Out-Null

if ($LASTEXITCODE -ne 0) { throw "Falha ao subir o container." }

Start-Sleep -Seconds 2
Write-Host ""
Write-Host "App disponivel em http://localhost:$Port" -ForegroundColor Green
if ($Pwa) {
    Write-Host "Service worker ATIVO: se vir a versao antiga, limpe o site em" -ForegroundColor Yellow
    Write-Host "DevTools > Application > Storage > Clear site data." -ForegroundColor Yellow
} else {
    Write-Host "Basta recarregar a pagina (F5)." -ForegroundColor DarkGray
}
