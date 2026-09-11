# Sua Barbearia — App Flutter

Aplicativo único para **Android, iOS e Flutter Web**, consumindo a API REST do
backend Django. Três experiências em um só binário, escolhidas pelo papel do
usuário autenticado: **OWNER**, **BARBER** e **CLIENT**.

> **O backend fica em outro repositório** (`sua-barbearia-backend`), com o
> seu próprio `docker-compose`. Suba-o primeiro — o app precisa da API em
> `http://localhost:8000`. Os dois stacks Docker são independentes e não
> compartilham rede: o app roda no navegador (ou no celular) e o que autoriza a
> chamada é o `CORS_ALLOWED_ORIGINS` do backend, que já libera a porta 8080.

## Subindo com Docker

Não precisa ter o Flutter SDK instalado: a imagem compila o app e o serve com
Nginx.

```bash
cp .env.example .env
docker compose up --build -d      # http://localhost:8080
docker compose logs -f web
docker compose down
```

> O app é servido como **build estático**. Reiniciar o container **não** aplica
> alteração de código — é preciso reconstruir a imagem
> (`docker compose up --build -d`). Para o ciclo de desenvolvimento, prefira o
> `scripts/web.ps1` abaixo: ele recompila reaproveitando o cache do pub e do
> `.dart_tool`, o que é bem mais rápido do que um build de imagem.

O `.env` é lido pelo **Compose** e vira build arg — não é lido em tempo de
execução:

| Variável | Padrão | Para que serve |
|---|---|---|
| `WEB_PORT` | `8080` | Porta publicada no host |
| `API_BASE_URL` | *(vazio)* | Vazio = descobre o backend pelo endereço da página |
| `ENABLE_NETWORK_LOGS` | `false` | Logs de rede no console do navegador |
| `PWA_STRATEGY` | `none` | `offline-first` só em produção de verdade |
| `FLUTTER_VERSION` | `stable` | Fixe (ex.: `3.47.2`) para builds reproduzíveis |

### Toolchain sem instalar o SDK

```bash
docker compose run --rm toolchain flutter analyze
docker compose run --rm toolchain flutter test
docker compose run --rm toolchain dart format lib test
docker compose run --rm toolchain flutter build apk --debug
```

O serviço `toolchain` monta o código e usa um volume nomeado para o pub cache.
Esse volume é importante: sem ele o `--rm` descarta os pacotes baixados e o
`analyze` acusa centenas de erros falsos de import.

## Executando com o SDK local

```bash
flutter pub get

flutter run -d chrome     # Web
flutter run -d android    # Android
flutter run -d ios        # iOS (macOS)
```

A URL da API é injetada em tempo de compilação:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Padrões quando `API_BASE_URL` não é informada:

| Plataforma | URL |
|---|---|
| Web | Mesmo host da página, porta 8000 |
| iOS / Desktop | `http://localhost:8000` |
| Emulador Android | `http://10.0.2.2:8000` |

## Ciclo de desenvolvimento do web (script)

`scripts/web.ps1` compila e sobe o app web usando a imagem oficial do Flutter —
não é preciso instalar o SDK, e o build é incremental:

```powershell
.\scripts\web.ps1              # compila e (re)inicia em http://localhost:8080
.\scripts\web.ps1 -NoBuild     # só reinicia, sem recompilar
.\scripts\web.ps1 -Logs        # compila com logs de rede no console
.\scripts\web.ps1 -Api https://api.suabarbearia.com.br -Port 9090
```

O script cria um container chamado `sua_barbearia_web` e, antes de subir,
derruba o serviço `web` do Compose — os dois disputam a porta 8080. Para voltar
ao container gerenciado pelo Compose:

```bash
docker rm -f sua_barbearia_web
docker compose up --build -d
```

Sem `-Api`, o build web **descobre o backend a partir do endereço da página**
(mesmo host, porta 8000). Um único build funciona em `http://localhost:8080`, no
navegador do emulador Android (`http://10.0.2.2:8080`) e em outro aparelho da
rede local. Informe `-Api` apenas para apontar para outro ambiente.

## Testando no Android

### Emulador — app nativo (recomendado)

O `AppConfig` já usa `http://10.0.2.2:8000` por padrão no Android, que é o
alias do host da máquina dentro do emulador.

Com o SDK do Flutter instalado:

```bash
flutter run -d emulator-5554
```

Sem o SDK, compile o APK pelo `toolchain` e instale com o `adb` do Android
Studio:

```bash
docker compose run --rm toolchain flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Desde o Android 9 o tráfego sem TLS é bloqueado por padrão, e o backend de
desenvolvimento é HTTP puro. O manifesto de **debug** aponta para
`android/app/src/debug/res/xml/network_security_config.xml`, que libera HTTP em
claro. A liberação é ampla porque o elemento `<domain>` do Android casa **nomes
de host, não faixas de IP** — não dá para escrever "192.168.1.0/24", e o
endereço muda a cada rede. O que mantém isso seguro é o escopo: o arquivo existe
só em `src/debug/`, então o APK de **release** nunca o vê e segue exigindo
HTTPS.

### Emulador — build web pelo navegador

Serve para checar layout, não o comportamento nativo (armazenamento seguro,
push e toque diferem). Abra `http://10.0.2.2:8080` no navegador do emulador.
A origem `http://10.0.2.2:8080` já está liberada no `CORS_ALLOWED_ORIGINS` do
`.env` do **backend**.

### Aparelho físico na mesma rede

> **Atenção — o login falha em HTTP puro fora de `localhost`.**
> O `flutter_secure_storage` na Web usa AES-GCM via Web Crypto, que só existe
> em *secure context*: HTTPS ou `localhost`. Em `http://192.168.x.x:8080` o
> `window.isSecureContext` é `false` e `crypto.subtle` é `undefined`, então o
> token não pode ser guardado. O login é aceito pelo servidor, mas a requisição
> seguinte sai sem `Authorization` e volta 401.
>
> Não há gambiarra aqui: guardar o JWT em `localStorage` violaria a regra do
> projeto. Para testar no celular, torne a origem confiável no Chrome do
> aparelho — `chrome://flags/#unsafely-treat-insecure-origin-as-secure`,
> adicione `http://SEU_IP:8080`, marque **Enabled** e reinicie o navegador.
> Alternativa sem flag: publicar o app e a API por HTTPS (túnel ou certificado
> local) e apontar `API_BASE_URL` para a URL HTTPS da API.

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:8000
```

Acrescente `http://SEU_IP_LOCAL:8080` ao `CORS_ALLOWED_ORIGINS` no `.env` do
repositório `sua-barbearia-backend` e reinicie o backend.

## Produção

O app e a API são publicados no **mesmo domínio**. Quem atende a internet é o
nginx do repositório `sua-barbearia-backend`, que tem o certificado TLS e
reparte por caminho:

| Caminho | Destino |
|---|---|
| `/api/`, `/admin/`, `/health/`, `/static/`, `/media/` | Django |
| qualquer outro | este app |

Mesma origem significa que o navegador não faz requisição cross-origin: o CORS
não participa. E como é HTTPS, o `flutter_secure_storage` tem o *secure
context* de que precisa para guardar o JWT.

```bash
docker network create suabarbearia_edge     # uma vez, se ainda não existir
cp .env.prod.example .env                   # ajuste a API_BASE_URL
docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
```

Os dois `-f` não são opcionais: sem eles o Compose carrega só o arquivo de
desenvolvimento, publica a porta 8080 no host e não conecta o container à rede
compartilhada — o nginx do backend não encontraria o app.

A `API_BASE_URL` é gravada **na compilação**. Trocá-la exige `--build`;
reiniciar o container não muda nada.

O passo a passo completo da VM (DNS, firewall, TLS) está em
[`docs/DEPLOY.md`](../sua-barbearia-backend/docs/DEPLOY.md) do repositório do
backend.

## Qualidade

```bash
flutter analyze     # deve terminar com "No issues found!"
flutter test
dart format lib test
```

Sem o SDK instalado, os mesmos comandos via
`docker compose run --rm toolchain ...` (ver [Toolchain](#toolchain-sem-instalar-o-sdk)).

## Builds de release

```bash
flutter build web --release   --dart-define=API_BASE_URL=https://api.suabarbearia.com.br
flutter build apk --release   --dart-define=API_BASE_URL=https://api.suabarbearia.com.br
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.suabarbearia.com.br
flutter build ipa --release   --dart-define=API_BASE_URL=https://api.suabarbearia.com.br
```

A imagem Docker do web já faz o build de release. Para gerar a de produção com
service worker:

```bash
docker build --target runtime \
  --build-arg API_BASE_URL=https://api.suabarbearia.com.br \
  --build-arg PWA_STRATEGY=offline-first \
  -t sua-barbearia/web:latest .
```

## Arquitetura

Feature-first, com uma separação estrita entre camadas:

```
UI (features/)  →  Provider (providers/)  →  Repository (repositories/)  →  ApiClient
```

```
lib/
├── core/
│   ├── config/       AppConfig (URL da API, timeouts)
│   ├── theme/        AppColors, AppTypography, AppTheme, AppSpacing
│   ├── router/       AppRoutes + GoRouter com guarda por papel
│   ├── network/      ApiClient (Dio), AuthInterceptor, Paginated
│   ├── storage/      SecureStorage (tokens JWT)
│   ├── errors/       ApiException + tradução dos códigos da API
│   ├── responsive/   Responsive, ResponsiveBuilder, ContentContainer
│   └── utils/        Formatters (pt-BR/BRL), Validators
├── models/           Imutáveis, com fromJson/toJson escritos à mão
├── repositories/     auth, catalog, appointment, client, finance,
│                     inventory, engagement, dashboard
├── providers/        Riverpod: auth, catálogo, agenda, booking,
│                     dashboards, financeiro, estoque, engajamento
├── features/
│   ├── auth/         login, cadastro, recuperação de senha, splash
│   ├── owner/        dashboard, filiais, barbeiros, clientes, serviços,
│   │                 agenda, financeiro, produtos, estoque, relatórios
│   ├── barber/       dashboard, agenda do dia, atendimentos, perfil
│   ├── client/       home, agendamento, meus horários, histórico,
│   │                 fidelidade, perfil
│   └── shared/       shell de navegação, cartão de agendamento,
│                     ações de atendimento
└── widgets/          Design system (AppButton, AppTextField, AppCard, ...)
```

### Decisões de projeto

**Models escritos à mão, sem code generation.** O `pubspec.yaml` mantém
`freezed` e `json_serializable` nas `dev_dependencies` para quem quiser migrar,
mas os models são classes imutáveis com `fromJson`/`toJson`/`copyWith` escritos
manualmente. Assim o projeto compila com `flutter pub get` + `flutter run`, sem
depender de um passo de `build_runner` — e os conversores em
`models/json_utils.dart` toleram os tipos que o DRF envia (decimais como
string, datas ISO, campos nulos).

**Tokens só em armazenamento seguro.** `flutter_secure_storage`
(EncryptedSharedPreferences no Android, Keychain no iOS). Nunca em
SharedPreferences.

**Renovação transparente de sessão.** O `AuthInterceptor` intercepta o `401`,
renova o access token com o refresh e refaz a requisição original. Requisições
concorrentes compartilham o mesmo refresh. Se o refresh falhar, a sessão é
limpa e o app volta para o login.

**Erros com código estável.** O backend devolve `code` (ex.:
`SLOT_NOT_AVAILABLE`) e o app traduz para uma mensagem em português em
`core/errors/error_messages.dart`. O usuário nunca vê stack trace.

**Responsividade de verdade.** Nada de interface desktop “espremida” no
celular: no desktop há sidebar fixa e tabelas de dados; no mobile,
`NavigationBar`, cartões e bottom sheets. A quebra é feita por
`core/responsive/responsive.dart`.

**Estados de UX padronizados.** `AsyncView` cobre carregando (com skeleton),
erro (com “Tentar novamente”) e vazio (com ação) para todo consumo de API.

## Testes

```
test/
├── core/       validadores, formatação pt-BR, códigos de erro
├── models/     parsing do JSON real devolvido pela API
├── providers/  AuthController: login, logout, sessão expirada
└── widget/     tela de login: validação, envio e mensagens de erro
```

## Documentação da API

O contrato consumido por este app está no repositório do backend:

- `docs/API.md` — endpoints, envelope de resposta e códigos de erro.
- `docs/ARCHITECTURE.md` — arquitetura do sistema, ERD e regras de negócio.
- Swagger/ReDoc em `/api/docs/` e `/api/redoc/` com o backend rodando.
