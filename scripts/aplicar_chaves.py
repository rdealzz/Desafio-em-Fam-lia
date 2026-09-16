#!/usr/bin/env python3
"""Preenche lib/firebase_options.dart com as chaves copiadas do console.

Existe para quem não quer (ou não pode) rodar o Firebase CLI. No console do
Firebase, ao registrar um app, aparece um bloco assim:

    const firebaseConfig = {
      apiKey: "AIza...",
      authDomain: "meu-projeto.firebaseapp.com",
      projectId: "meu-projeto",
      storageBucket: "meu-projeto.firebasestorage.app",
      messagingSenderId: "123456789012",
      appId: "1:123456789012:web:abc123"
    };

Copie ele inteiro e rode:

    ./scripts/aplicar_chaves.py                 # cola e termina com Ctrl-D
    ./scripts/aplicar_chaves.py chaves.txt      # ou de um arquivo
    ./scripts/aplicar_chaves.py --plataforma android chaves.txt

Aceita o formato JavaScript do console, JSON puro ou uma chave por linha.
"""

import argparse
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ALVO = RAIZ / 'lib' / 'firebase_options.dart'

# Os campos que cada plataforma aceita, na ordem em que saem no arquivo.
# `web` é a que importa para o link que a família abre no navegador.
CAMPOS = {
    'web': ['apiKey', 'appId', 'messagingSenderId', 'projectId',
            'authDomain', 'storageBucket', 'measurementId'],
    'android': ['apiKey', 'appId', 'messagingSenderId', 'projectId',
                'storageBucket'],
    'ios': ['apiKey', 'appId', 'messagingSenderId', 'projectId',
            'storageBucket', 'iosBundleId'],
}

OBRIGATORIOS = ['apiKey', 'appId', 'messagingSenderId', 'projectId']


def extrair(texto):
    """Tira os pares chave/valor do que foi colado.

    Solta o parser em cima de qualquer coisa parecida com `chave: "valor"` em
    vez de exigir JSON válido: o console entrega JavaScript, e alguém colando
    de pressa traz `const firebaseConfig =` e o `;` junto.
    """
    try:
        return {k: str(v) for k, v in json.loads(texto).items()}
    except (ValueError, AttributeError):
        pass

    achados = {}
    padrao = re.compile(
        r'["\']?([A-Za-z_][A-Za-z0-9_]*)["\']?\s*[:=]\s*["\']([^"\']*)["\']')
    for chave, valor in padrao.findall(texto):
        if valor:
            achados[chave] = valor
    return achados


def bloco_dart(plataforma, config):
    linhas = [f'  static const FirebaseOptions {plataforma} = FirebaseOptions(']
    for campo in CAMPOS[plataforma]:
        valor = config.get(campo)
        if valor:
            linhas.append(f"    {campo}: '{valor}',")
    linhas.append('  );')
    return '\n'.join(linhas)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('arquivo', nargs='?',
                   help='arquivo com as chaves; sem ele, lê do teclado')
    p.add_argument('--plataforma', default='web', choices=sorted(CAMPOS),
                   help='qual seção preencher (padrão: web)')
    args = p.parse_args()

    if args.arquivo:
        texto = Path(args.arquivo).read_text(encoding='utf-8')
    else:
        print('Cole o bloco do console e termine com Ctrl-D:\n', file=sys.stderr)
        texto = sys.stdin.read()

    config = extrair(texto)
    faltando = [c for c in OBRIGATORIOS if not config.get(c)]
    if faltando:
        print(f'✗ Não achei no que você colou: {", ".join(faltando)}',
              file=sys.stderr)
        print('  Copie o bloco `const firebaseConfig = { ... }` inteiro.',
              file=sys.stderr)
        return 1

    # authDomain e storageBucket dão para deduzir do projectId quando o
    # console não mostrou (acontece em projeto antigo).
    projeto = config['projectId']
    config.setdefault('authDomain', f'{projeto}.firebaseapp.com')
    config.setdefault('storageBucket', f'{projeto}.firebasestorage.app')

    fonte = ALVO.read_text(encoding='utf-8')
    alvo_regex = re.compile(
        r'  static const FirebaseOptions ' + args.plataforma +
        r' = FirebaseOptions\(.*?\n  \);', re.S)
    if not alvo_regex.search(fonte):
        print(f'✗ Não achei a seção `{args.plataforma}` em {ALVO}',
              file=sys.stderr)
        return 1

    novo = alvo_regex.sub(lambda _: bloco_dart(args.plataforma, config), fonte)

    # O aviso no topo só faz sentido enquanto o arquivo é de exemplo.
    novo = re.sub(r'\A// ATENÇÃO: arquivo de exemplo\.\n(//.*\n|\n)*?(?=import )',
                  '// Gerado a partir das chaves do console do Firebase.\n'
                  '//\n'
                  '// Chave de cliente do Firebase é pública por natureza: quem protege os\n'
                  '// dados são as regras em firestore.rules e storage.rules, não o segredo\n'
                  '// destes valores. Por isso o arquivo fica versionado.\n'
                  '//\n'
                  '// Para regerar: ./scripts/aplicar_chaves.py (ou flutterfire configure).\n',
                  novo)

    ALVO.write_text(novo, encoding='utf-8')
    print(f'✓ Seção `{args.plataforma}` preenchida com o projeto {projeto}')
    print(f'  {ALVO.relative_to(RAIZ)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
