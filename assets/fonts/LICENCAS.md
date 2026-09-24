# Fontes empacotadas

## Inter — `Inter-Regular.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf`
SIL Open Font License 1.1 · https://github.com/rsms/inter

## AnimalEmoji — `AnimalEmoji.ttf`
Recorte da **Noto Color Emoji**, do projeto Noto Emoji do Google.
SIL Open Font License 1.1 · https://github.com/googlefonts/noto-emoji

Contém só os 22 desenhos de bicho usados nos avatares (44 KB; o arquivo
original passa de 10 MB). A OFL permite subconjunto e redistribuição desde que
o resultado continue sob a mesma licença, que é o caso.

Para gerar de novo:

```sh
pip install fonttools
curl -L -o NotoColorEmoji.ttf \
  https://raw.githubusercontent.com/googlefonts/noto-emoji/main/fonts/NotoColorEmoji.ttf
python3 -m fontTools.subset NotoColorEmoji.ttf \
  --unicodes=U+1F436,U+1F431,U+1F98A,U+1F43B,U+1F43C,U+1F428,U+1F42F,U+1F981,U+1F42E,U+1F437,U+1F438,U+1F435,U+1F427,U+1F989,U+1F984,U+1F422,U+1F988,U+1F42C,U+1F985,U+1F43A,U+1F98B,U+1F434 \
  --no-layout-closure \
  --output-file=assets/fonts/AnimalEmoji.ttf
```

A lista de pontos de código tem de bater com `lib/widgets/ui/avatar_animals.dart`.
