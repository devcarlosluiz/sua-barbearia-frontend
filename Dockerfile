# syntax=docker/dockerfile:1
#
# Compila o Flutter Web e serve o resultado com Nginx.
#
# O app é um build ESTÁTICO: reiniciar o container não aplica alteração de
# código — é preciso reconstruir a imagem (`docker compose up --build`). Para o
# ciclo de desenvolvimento, `scripts/web.ps1` recompila reaproveitando o cache
# do pub e do `.dart_tool`, o que é bem mais rápido do que um build de imagem.

ARG FLUTTER_VERSION=stable

# ---------- Build ----------
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build

WORKDIR /app

# `pub get` antes do código: enquanto o pubspec não mudar, o Docker reaproveita
# esta camada e não baixa os pacotes de novo.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Sem `API_BASE_URL` o app deriva o backend do endereço da própria página
# (mesmo host, porta 8000). Assim um único build funciona em
# http://localhost:8080, no navegador do emulador Android (10.0.2.2:8080) e em
# outro aparelho da rede local. Informe explicitamente só para apontar para
# outro ambiente (ex.: https://api.suabarbearia.com.br).
ARG API_BASE_URL=""
ARG ENABLE_NETWORK_LOGS="false"

# `none` = sem service worker. Ligado, ele serve o build antigo mesmo após
# recompilar — e nem Ctrl+Shift+R resolve, porque ele intercepta as
# requisições. Use `offline-first` só em builds de produção de verdade.
#
# ATENÇÃO: `--pwa-strategy` está DEPRECADO (flutter/flutter#156910) e, no stable
# atual, já NÃO TEM EFEITO: verificado nesta versão, o build gera o
# `flutter_service_worker.js` mesmo com `none`, e o `flutter_bootstrap.js`
# continua chamando `navigator.serviceWorker.register(...)`. Por isso a etapa
# seguinte apaga o arquivo à mão — é o que realmente desliga o service worker.
#
# Deixe vazio (`PWA_STRATEGY=`) para não passar a flag, quando ela for removida.
ARG PWA_STRATEGY="none"

# A fonte de ícones vai inteira, sem tree-shaking: o tree-shaking gera uma
# fonte sob medida a cada build, com os glifos remapeados. Se o navegador
# reaproveitar a fonte de um build anterior, os códigos não batem e alguns
# ícones simplesmente não são desenhados. Custa ~1,6 MB em vez de ~28 KB.
RUN set -eux; \
    FLAGS="--no-tree-shake-icons"; \
    if [ -n "$API_BASE_URL" ]; then \
        FLAGS="$FLAGS --dart-define=API_BASE_URL=$API_BASE_URL"; \
    fi; \
    if [ "$ENABLE_NETWORK_LOGS" = "true" ]; then \
        FLAGS="$FLAGS --dart-define=ENABLE_NETWORK_LOGS=true"; \
    fi; \
    if [ -n "$PWA_STRATEGY" ]; then \
        FLAGS="$FLAGS --pwa-strategy=$PWA_STRATEGY"; \
    fi; \
    flutter build web --release $FLAGS

# Desliga o service worker de verdade.
#
# O `--pwa-strategy=none` acima não basta (ver comentário do ARG): o arquivo é
# gerado de qualquer forma. Com ele no disco, o navegador o registra e passa a
# servir o build antigo — inclusive depois de reconstruir a imagem. Sem ele, o
# `register()` recebe 404, falha em silêncio e o app roda sempre do servidor.
RUN set -eux; \
    if [ "$PWA_STRATEGY" = "none" ]; then \
        rm -f build/web/flutter_service_worker.js; \
        echo "service worker: desligado"; \
    fi

# --- Versionamento do bundle (cache busting) -------------------------------
# O Flutter Web NÃO coloca hash nos nomes: o build gera sempre `main.dart.js`,
# `flutter_bootstrap.js` e `assets/fonts/MaterialIcons-Regular.otf`. Com nomes
# fixos, qualquer cache de navegador pode continuar servindo a versão antiga.
#
# A correção durável é dar a cada build uma URL própria. O `index.html` é
# servido com `no-store` (ver docker/nginx/flutter-web.conf), então chega sempre
# novo; com a versão no `<base href>`, TODAS as URLs relativas — JS, fontes,
# assets — passam a apontar para um prefixo inédito a cada build, e o Nginx
# remove o prefixo ao servir.
RUN set -eux; \
    if [ -f build/web/main.dart.js ]; then \
        VERSION="$(md5sum build/web/main.dart.js | cut -c1-12)"; \
        sed -i "s|<base href=\"[^\"]*\">|<base href=\"/v/${VERSION}/\">|" build/web/index.html; \
        echo "versao do bundle: ${VERSION}"; \
    else \
        echo "AVISO: main.dart.js nao encontrado; bundle sem versionamento"; \
    fi

# ---------- Runtime ----------
FROM nginx:1.27-alpine AS runtime

COPY docker/nginx/flutter-web.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost/index.html > /dev/null || exit 1
