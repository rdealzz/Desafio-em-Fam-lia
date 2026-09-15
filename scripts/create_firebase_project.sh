#!/usr/bin/env bash
#
# Cria um projeto Firebase novo para o "Desafio em Família" e já o liga ao app.
#
#   ./scripts/create_firebase_project.sh
#   ./scripts/create_firebase_project.sh meu-id-preferido
#
# Automatiza o que o Firebase CLI permite:
#   1. cria o projeto no Google Cloud + Firebase
#   2. cria o banco Firestore em São Paulo
#   3. chama o setup_firebase.sh, que gera as pastas nativas, registra os apps
#      Android/iOS pelo flutterfire e publica as regras
#
# Quem registra os apps é o `flutterfire configure`, não este script: ele lê o
# applicationId e o bundle id reais do projeto nativo. Registrar na mão daria
# IDs errados (o iOS usa desafioEmFamilia, o Android desafio_em_familia).
#
# Duas coisas o CLI não faz e você clica no console (o script abre os links e
# espera):
#   • ativar o login por e-mail/senha
#   • criar o bucket do Storage
#
# ATENÇÃO: isto cria recursos de verdade na SUA conta Google. Nada é cobrado
# no plano gratuito, mas o Storage exige o plano Blaze (ver README do script).

set -euo pipefail

cd "$(dirname "$0")/.."

BOLD=$'\033[1m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'; BLUE=$'\033[0;34m'; OFF=$'\033[0m'

step() { echo; echo "${BLUE}${BOLD}▶ $*${OFF}"; }
ok()   { echo "${GREEN}  ✓ $*${OFF}"; }
warn() { echo "${YELLOW}  ! $*${OFF}"; }
die()  { echo "${RED}  ✗ $*${OFF}" >&2; exit 1; }

DISPLAY_NAME="Desafio em Familia"
LOCATION="${FIRESTORE_LOCATION:-southamerica-east1}"

# IDs de projeto são únicos no mundo inteiro — o sufixo evita colisão.
if [ -n "${1:-}" ]; then
  PROJECT_ID="$1"
else
  PROJECT_ID="desafio-familia-$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
fi

# Regra do Google: 6-30 caracteres, minúsculas, dígitos e hífen, começa com letra.
echo "$PROJECT_ID" | grep -qE '^[a-z][a-z0-9-]{4,28}[a-z0-9]$' \
  || die "ID inválido: '$PROJECT_ID' (6-30 caracteres, minúsculas, começando com letra)"

# ------------------------------------------------------------- ferramentas
step "Conferindo as ferramentas"

command -v flutter >/dev/null 2>&1 || die \
  "Flutter não encontrado. https://docs.flutter.dev/get-started/install"
ok "flutter"

if ! command -v firebase >/dev/null 2>&1; then
  command -v npm >/dev/null 2>&1 || die "npm não encontrado. Instale o Node.js."
  warn "instalando o Firebase CLI"
  npm install -g firebase-tools
fi
ok "firebase-tools $(firebase --version)"

# ------------------------------------------------------------------- login
step "Entrando na sua conta Google"

if firebase projects:list >/dev/null 2>&1; then
  ok "já autenticado"
else
  echo "  Uma janela do navegador vai abrir."
  firebase login || die "login não concluído"
fi

ACCOUNT=$(firebase login:list 2>/dev/null | grep -oE '[[:alnum:]._%+-]+@[[:alnum:].-]+' | head -1 || true)
[ -n "$ACCOUNT" ] && ok "conta: $ACCOUNT"

# ------------------------------------------------------------ criar projeto
step "Criando o projeto $PROJECT_ID"

if firebase projects:list 2>/dev/null | grep -q "$PROJECT_ID"; then
  ok "projeto já existe — seguindo em frente"
else
  if ! firebase projects:create "$PROJECT_ID" --display-name "$DISPLAY_NAME"; then
    echo
    warn "a criação falhou. Causas mais comuns:"
    warn "  • primeira vez na conta: aceite os termos em https://console.firebase.google.com"
    warn "  • cota de projetos atingida (o padrão é baixo em contas novas)"
    warn "  • o ID '$PROJECT_ID' já existe no mundo — rode de novo para sortear outro"
    die "interrompido"
  fi
  ok "projeto criado"
fi

# ---------------------------------------------------------------- firestore
step "Criando o banco Firestore em $LOCATION"

if firebase firestore:databases:list --project "$PROJECT_ID" 2>/dev/null \
     | grep -q "(default)"; then
  ok "banco (default) já existe"
elif firebase firestore:databases:create "(default)" \
       --location "$LOCATION" --project "$PROJECT_ID"; then
  ok "banco criado em $LOCATION"
else
  warn "não consegui criar o banco pelo CLI"
  warn "crie em: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
  warn "região: $LOCATION — ela NÃO pode ser trocada depois"
fi

# ------------------------------------------------- os dois cliques manuais
step "Dois ajustes que só o console faz"

cat <<EOF

  ${BOLD}1. Ativar o login por e-mail/senha${OFF}
     https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers
     → Sign-in method → E-mail/senha → Ativar → Salvar

  ${BOLD}2. Criar o bucket do Storage${OFF}
     https://console.firebase.google.com/project/$PROJECT_ID/storage
     → Começar → modo produção → região $LOCATION

     ${YELLOW}Projetos novos precisam do plano Blaze para usar o Storage.${OFF}
     ${YELLOW}O Blaze tem cota gratuita generosa, mas pede cartão.${OFF}
     ${YELLOW}Sem Storage o app funciona: a foto comprovante é opcional.${OFF}

EOF

read -r -p "  Fez os dois (ou quer seguir sem o Storage)? [Enter para continuar] " _

# ---------------------------------------------------------- ligar o app
step "Ligando o app ao projeto"
exec ./scripts/setup_firebase.sh "$PROJECT_ID"
