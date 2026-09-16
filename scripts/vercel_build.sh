#!/usr/bin/env bash
#
# Build da versão web para a Vercel.
#
# A Vercel não traz Flutter, então o script baixa o SDK antes de compilar.
# O primeiro deploy demora alguns minutos por causa disso.
#
# Se a compilação falhar, o script NÃO derruba o deploy: publica uma página de
# diagnóstico com o erro. Um 404 não diz nada; uma página com o log diz tudo.

set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"
# "stable" acompanha o canal atual. Para travar numa versão específica:
#   FLUTTER_VERSION=3.24.5 (variável de ambiente no painel da Vercel)
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
LOG="$RAIZ/build-web.log"
SAIDA="$RAIZ/build/web"

mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
: > "$LOG"

registrar() { echo "$@" | tee -a "$LOG"; }

registrar "=== ambiente ==="
registrar "pwd:  $RAIZ"
registrar "home: $HOME"
registrar "git:  $(git --version 2>&1 || echo ausente)"
registrar "disco:"
df -h "$HOME" 2>&1 | tail -2 | tee -a "$LOG"

compilar() {
  if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
    registrar ""
    registrar "=== baixando o Flutter ($FLUTTER_VERSION) ==="
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$FLUTTER_DIR" 2>&1 | tee -a "$LOG"
  else
    registrar "Flutter já presente em $FLUTTER_DIR"
  fi

  export PATH="$FLUTTER_DIR/bin:$PATH"
  # O build da Vercel roda com outro dono no diretório do git.
  git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true
  git config --global --add safe.directory "$RAIZ" 2>/dev/null || true

  registrar ""
  registrar "=== versão ==="
  flutter --version 2>&1 | tee -a "$LOG" || return 1

  # Só os artefatos de web: sem isso o SDK baixa Android, iOS, Linux, Windows
  # e macOS à toa — minutos e centenas de MB desperdiçados num build de web.
  registrar ""
  registrar "=== preparando artefatos de web ==="
  flutter precache --web --no-android --no-ios --no-linux --no-windows \
    --no-macos --no-fuchsia 2>&1 | tee -a "$LOG" || return 1

  flutter config --enable-web --no-analytics 2>&1 | tee -a "$LOG" || true

  registrar ""
  registrar "=== dependências ==="
  flutter pub get 2>&1 | tee -a "$LOG" || return 1

  registrar ""
  registrar "=== compilando ==="
  # O app publicado fala com o Firebase real. As chaves vêm da seção `web` de
  # lib/firebase_options.dart, gerada por ./scripts/setup_firebase.sh.
  flutter build web --release 2>&1 | tee -a "$LOG" || return 1

  [ -f "$SAIDA/index.html" ] || return 1
  return 0
}

if compilar; then
  registrar ""
  registrar "✅ build em $SAIDA"
  exit 0
fi

# ---------------------------------------------------------------------------
# Falhou. Em vez de deixar a Vercel sem nada para servir (o que vira 404),
# publica o diagnóstico: assim dá para ler o erro direto na URL.
# ---------------------------------------------------------------------------
registrar ""
registrar "❌ a compilação falhou — publicando página de diagnóstico"

mkdir -p "$SAIDA"
{
  echo '<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">'
  echo '<meta name="viewport" content="width=device-width,initial-scale=1">'
  echo '<title>Build falhou — Desafio em Família</title><style>'
  echo 'body{margin:0;padding:24px;background:#1C1B2E;color:#E8E6F5;'
  echo 'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;'
  echo 'line-height:1.55}h1{font-size:20px;margin:0 0 4px}'
  echo '.sub{color:#9B97BD;font-size:14px;margin-bottom:20px}'
  echo 'pre{background:#0F0E1C;border:1px solid #33314F;border-radius:12px;'
  echo 'padding:16px;overflow:auto;font-size:12px;color:#9BE8B0;max-height:70vh}'
  echo '.box{background:#2A2842;border-radius:12px;padding:16px;margin-bottom:20px;'
  echo 'font-size:14px}</style></head><body>'
  echo '<h1>⚠️ O deploy subiu, mas a compilação do app falhou</h1>'
  echo '<div class="sub">Esta página existe para você ver o motivo em vez de um 404.</div>'
  echo '<div class="box">Copie o final do log abaixo e mande para quem estiver'
  echo ' ajudando no código — o erro está aí.</div>'
  echo '<pre>'
  tail -c 60000 "$LOG" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
  echo '</pre></body></html>'
} > "$SAIDA/index.html"

# Sai com 0 de propósito: o deploy conclui e serve o diagnóstico.
exit 0
