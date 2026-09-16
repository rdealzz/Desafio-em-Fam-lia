#!/usr/bin/env bash
#
# Liga o "Desafio em Família" a um projeto Firebase real.
#
#   ./scripts/setup_firebase.sh                 # pergunta o projeto
#   ./scripts/setup_firebase.sh meu-projeto-id  # usa esse projeto direto
#
# O que ele faz, em ordem:
#   1. confere as ferramentas (flutter, firebase, flutterfire)
#   2. gera as pastas nativas android/ e ios/ se ainda não existirem
#   3. roda `flutterfire configure` (aqui você loga na sua conta Google)
#   4. ajusta a configuração nativa que o Firebase e o image_picker exigem
#   5. publica as regras e os índices do Firestore/Storage
#
# É seguro rodar de novo: cada passo checa antes de mexer.

set -euo pipefail

cd "$(dirname "$0")/.."

BOLD=$'\033[1m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'; BLUE=$'\033[0;34m'; OFF=$'\033[0m'

step() { echo; echo "${BLUE}${BOLD}▶ $*${OFF}"; }
ok()   { echo "${GREEN}  ✓ $*${OFF}"; }
warn() { echo "${YELLOW}  ! $*${OFF}"; }
die()  { echo "${RED}  ✗ $*${OFF}" >&2; exit 1; }

PROJECT_ID="${1:-}"
ORG="${FLUTTER_ORG:-com.desafioemfamilia}"

# ---------------------------------------------------------------- 1. tooling
step "Conferindo as ferramentas"

command -v flutter >/dev/null 2>&1 || die \
  "Flutter não encontrado. Instale em https://docs.flutter.dev/get-started/install"
ok "flutter $(flutter --version 2>/dev/null | head -1 | awk '{print $2}')"

if ! command -v firebase >/dev/null 2>&1; then
  warn "Firebase CLI não encontrado — instalando via npm"
  command -v npm >/dev/null 2>&1 || die \
    "npm não encontrado. Instale o Node.js ou o Firebase CLI manualmente."
  npm install -g firebase-tools
fi
ok "firebase-tools $(firebase --version 2>/dev/null)"

if ! command -v flutterfire >/dev/null 2>&1; then
  warn "flutterfire_cli não encontrado — instalando"
  dart pub global activate flutterfire_cli
  export PATH="$PATH:$HOME/.pub-cache/bin"
fi
command -v flutterfire >/dev/null 2>&1 || die \
  "flutterfire ainda fora do PATH. Adicione \$HOME/.pub-cache/bin ao PATH e rode de novo."
ok "flutterfire pronto"

# --------------------------------------------------- 2. plataformas nativas
step "Plataformas nativas"

if [ -d android ] && [ -d ios ]; then
  ok "android/ e ios/ já existem"
else
  echo "  gerando android/ e ios/ (org: $ORG)"
  flutter create . \
    --project-name desafio_em_familia \
    --org "$ORG" \
    --platforms=android,ios
  ok "plataformas geradas"
fi

echo "  baixando dependências"
flutter pub get
ok "dependências instaladas"

# ------------------------------------------------------- 3. conectar projeto
step "Conectando ao projeto Firebase"
echo "  Uma janela do navegador vai abrir para você entrar na conta Google."
echo "  O projeto precisa ter Authentication (e-mail/senha), Firestore e Storage ativados."
echo

firebase login --no-localhost || firebase login

# web junto: a família vai usar pelo navegador, e é a seção `web` de
# firebase_options.dart que a página publicada lê. Sem ela o link abre a tela
# de configuração mesmo com o celular funcionando.
if [ -n "$PROJECT_ID" ]; then
  flutterfire configure --project="$PROJECT_ID" \
    --platforms=android,ios,web --yes
else
  flutterfire configure --platforms=android,ios,web
fi

if grep -q "COLE_" lib/firebase_options.dart 2>/dev/null; then
  die "firebase_options.dart ainda tem placeholders — o configure não concluiu."
fi
ok "lib/firebase_options.dart preenchido"

DETECTED_PROJECT=$(grep -m1 "projectId:" lib/firebase_options.dart | sed "s/.*'\(.*\)'.*/\1/")
ok "projeto: $DETECTED_PROJECT"

# --------------------------------------------------- 4. ajustes nativos
step "Ajustes nativos"

# firebase_auth 5.x exige minSdk 23; o padrão do Flutter ainda é menor.
patch_min_sdk() {
  local file="$1"
  [ -f "$file" ] || return 1
  if grep -qE "minSdk(Version)?\s*=?\s*23" "$file"; then
    ok "minSdk já em 23 ($file)"
    return 0
  fi
  if grep -q "flutter.minSdkVersion" "$file"; then
    sed -i.bak "s/flutter\.minSdkVersion/23/" "$file" && rm -f "$file.bak"
    ok "minSdk ajustado para 23 ($file)"
    return 0
  fi
  return 1
}

if ! patch_min_sdk android/app/build.gradle.kts && \
   ! patch_min_sdk android/app/build.gradle; then
  warn "não consegui ajustar o minSdk — confira à mão: minSdk = 23 em android/app/build.gradle"
fi

# O image_picker trava no iOS sem estas descrições de permissão.
PLIST="ios/Runner/Info.plist"
if [ -f "$PLIST" ]; then
  add_plist_key() {
    local key="$1" text="$2"
    if grep -q "$key" "$PLIST"; then
      ok "$key já presente"
    elif command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
      /usr/libexec/PlistBuddy -c "Add :$key string $text" "$PLIST"
      ok "$key adicionado"
    else
      warn "adicione à mão em $PLIST: <key>$key</key><string>$text</string>"
    fi
  }
  add_plist_key NSCameraUsageDescription \
    "Para tirar a foto que comprova a atividade."
  add_plist_key NSPhotoLibraryUsageDescription \
    "Para escolher a foto que comprova a atividade."
else
  warn "$PLIST não encontrado (normal fora do macOS)"
fi

# ------------------------------------------------------ 5. regras e índices
step "Publicando regras e índices"

firebase use "$DETECTED_PROJECT" 2>/dev/null || true

if firebase deploy --only firestore:rules,firestore:indexes,storage \
     --project "$DETECTED_PROJECT"; then
  ok "regras e índices publicados"
else
  warn "o deploy falhou — normalmente é Firestore ou Storage ainda não criado"
  warn "crie os dois no console e rode: firebase deploy --only firestore,storage"
fi

# ------------------------------------------------------------------- pronto
echo
echo "${GREEN}${BOLD}✅ Firebase ligado ao projeto $DETECTED_PROJECT${OFF}"
echo
echo "${BOLD}Agora, na sua máquina:${OFF}"
echo "  flutter run"
echo
echo "${BOLD}Para o link que a família abre no navegador:${OFF}"
echo "  git add lib/firebase_options.dart && git commit -m 'chaves do Firebase'"
echo "  git push"
echo
echo "  As chaves de cliente do Firebase são públicas por natureza — quem"
echo "  protege os dados são as regras do Firestore, já publicadas acima."
echo
echo "  No console do Firebase, em Authentication > Settings > Authorized"
echo "  domains, acrescente o domínio publicado. Sem isso o login falha no"
echo "  navegador, mesmo com as chaves certas."
echo
echo "${BOLD}Primeira pessoa:${OFF} cria a conta em \"Criar família\" e compartilha"
echo "o código do convite (⋮ no dashboard) com os outros três."
