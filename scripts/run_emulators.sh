#!/usr/bin/env bash
#
# Sobe o Firebase Emulator Suite para rodar o app sem conta Firebase.
#
#   Terminal 1:  ./scripts/run_emulators.sh
#   Terminal 2:  flutter run --dart-define=USE_FIREBASE_EMULATOR=true
#
# O projeto "demo-desafio-em-familia" tem o prefixo `demo-`, que o Firebase CLI
# reconhece: nada sai para a nuvem e nenhuma credencial é necessária.
#
# Em aparelho físico, passe também o IP do computador:
#   flutter run --dart-define=USE_FIREBASE_EMULATOR=true \
#               --dart-define=FIREBASE_EMULATOR_HOST=192.168.0.10

set -euo pipefail

cd "$(dirname "$0")/.."

BOLD=$'\033[1m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; OFF=$'\033[0m'

PROJECT="demo-desafio-em-familia"

if ! command -v firebase >/dev/null 2>&1; then
  echo "${YELLOW}Firebase CLI não encontrado. Instalando...${OFF}"
  command -v npm >/dev/null 2>&1 || {
    echo "npm não encontrado. Instale o Node.js primeiro." >&2
    exit 1
  }
  npm install -g firebase-tools
fi

# Os emuladores rodam sobre a JVM.
if ! command -v java >/dev/null 2>&1; then
  echo "${YELLOW}Java não encontrado — os emuladores de Firestore e Storage precisam dele.${OFF}"
  echo "macOS:  brew install openjdk"
  echo "Ubuntu: sudo apt install default-jre"
  exit 1
fi

echo "${BOLD}Subindo os emuladores (projeto $PROJECT)${OFF}"
echo "  Auth      → localhost:9099"
echo "  Firestore → localhost:8080"
echo "  Storage   → localhost:9199"
echo "  Painel    → ${GREEN}http://localhost:4000${OFF}"
echo
echo "No outro terminal:"
echo "  ${BOLD}flutter run --dart-define=USE_FIREBASE_EMULATOR=true${OFF}"
echo

# --import/--export mantém os dados entre reinícios: a família de teste não
# some toda vez que você reinicia os emuladores.
mkdir -p .emulator-data

exec firebase emulators:start \
  --project "$PROJECT" \
  --import=.emulator-data \
  --export-on-exit=.emulator-data
