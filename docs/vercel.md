# Publicar a versão web na Vercel

A página publicada roda em **modo demonstração**: dados de mentira, sem
Firebase, sem conta. Serve para ver a interface e mostrar para a família.

---

## O que 404 significa

**Vercel devolve 404 quando não existe nenhum deploy concluído naquela URL.**
Não é cache nem propagação — é ausência de página. Três causas, nesta ordem de
probabilidade:

### 1. O repositório não está ligado à Vercel

O mais comum, e o único passo que ninguém faz por você.

1. <https://vercel.com/new>
2. **Import Git Repository** → escolha `rdealzz/Desafio-em-Fam-lia`
3. **Root Directory**: deixe na raiz (`./`) — não aponte para `web/` nem
   `build/`
4. **Framework Preset**: `Other`
5. Não mexa em Build Command nem Output Directory: o `vercel.json` já define
6. **Deploy**

> Se o projeto já existe mas nunca teve deploy verde, vá em
> **Deployments → Redeploy** depois de conferir os itens acima.

### 2. O build falhou

A partir de agora isso **não gera mais 404**: se a compilação falhar, o script
publica uma página escura com o log do erro. Se você vê essa página, copie o
final do log — é ali que está o motivo.

Se ainda assim vier 404, o build nem chegou a rodar. Veja o log em
**Deployments → o deploy → Building**.

### 3. Root Directory apontando para o lugar errado

Nas configurações do projeto, **Settings → General → Root Directory** precisa
estar vazio ou `./`. Apontando para `web/`, a Vercel não acha o `vercel.json`
e não sabe compilar nada.

---

## Como o build funciona

A Vercel não traz Flutter. Então `scripts/vercel_build.sh`:

1. clona o Flutter (`--depth 1`) se ainda não estiver em cache
2. roda `flutter precache --web` — só os artefatos de web, sem baixar Android,
   iOS, Linux, Windows e macOS à toa
3. `flutter pub get`
4. `flutter build web --release --dart-define=DEMO_MODE=true`
5. se qualquer passo falhar, publica a página de diagnóstico em vez de deixar
   o deploy sem saída

**O primeiro deploy demora** — são alguns minutos só para baixar o SDK. Os
seguintes reaproveitam o cache da Vercel quando ela mantém o `$HOME`.

---

## Travar a versão do Flutter

Se um dia o canal `stable` quebrar o build, dá para fixar sem tocar no código.
Em **Settings → Environment Variables**:

```
FLUTTER_VERSION = 3.24.5
```

---

## Testar o build na sua máquina

Se você tem Flutter instalado, dá para reproduzir exatamente o que a Vercel faz:

```bash
flutter build web --release --dart-define=DEMO_MODE=true
# e servir o resultado:
cd build/web && python3 -m http.server 8000
```

Ou rodar direto no navegador, sem build:

```bash
flutter run -d chrome --dart-define=DEMO_MODE=true
```

---

## Publicar ligado no Firebase de verdade

A demonstração existe porque não há projeto Firebase conectado ainda. Quando
houver:

1. preencha a seção `web` de `lib/firebase_options.dart`
   (`flutterfire configure` faz isso)
2. tire `--dart-define=DEMO_MODE=true` de `scripts/vercel_build.sh`
3. no console do Firebase, **Authentication → Settings → Authorized domains**,
   acrescente o domínio da Vercel — sem isso o login falha no navegador

Aí a família inteira usa o app abrindo um link, sem instalar nada. O
`manifest.json` já permite adicionar à tela inicial do celular.
