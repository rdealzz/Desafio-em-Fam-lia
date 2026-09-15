#!/usr/bin/env bash
#
# Build da versão web para a Vercel.
#
# A Vercel não tem Flutter instalado, então o script baixa o SDK antes de
# compilar. O clone raso (~200 MB) leva alguns minutos no primeiro deploy.
#
# Configurado em vercel.json; não precisa rodar isso à mão.

set -euo pipefail

FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "▶ Baixando o Flutter ($FLUTTER_VERSION)…"
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# O ambiente de build da Vercel roda como outro dono do diretório do git.
git config --global --add safe.directory "$FLUTTER_DIR" || true

flutter --version
flutter config --enable-web
flutter pub get

# DEMO_MODE: a página pública mostra a interface com dados de mentira, sem
# Firebase. Para publicar ligado no Firebase de verdade, tire o define e
# preencha lib/firebase_options.dart com as chaves web.
flutter build web --release --dart-define=DEMO_MODE=true

echo "✅ Build em build/web"
