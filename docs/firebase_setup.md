# Ligando o Firebase

Dois caminhos. O primeiro não precisa de conta nenhuma e serve para ver o app
funcionando hoje; o segundo é o que a família vai usar de verdade.

---

## Caminho A — Emulador (sem conta Firebase)

Roda Auth, Firestore e Storage na sua máquina. Dá para criar a família,
registrar atividade, subir foto e usar as cartas — tudo local.

```bash
# Terminal 1
./scripts/run_emulators.sh

# Terminal 2
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

Painel dos emuladores: <http://localhost:4000> — dá para ver os documentos do
Firestore sendo criados enquanto você mexe no app.

Precisa de **Java** (os emuladores de Firestore e Storage rodam na JVM) e do
**Firebase CLI** — o script instala o CLI se faltar.

Os dados ficam em `.emulator-data/` e sobrevivem ao reinício dos emuladores
(a pasta está no `.gitignore`).

**Em aparelho físico**, o `localhost` do celular não é o do computador. Passe
o IP da sua máquina na rede:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true \
            --dart-define=FIREBASE_EMULATOR_HOST=192.168.0.10
```

No emulador do Android isso não é necessário: o app já usa `10.0.2.2`
automaticamente.

---

## Caminho B — Projeto Firebase real

### Não tenho projeto ainda

Um comando cria o projeto e liga o app nele:

```bash
./scripts/create_firebase_project.sh
# ou, se quiser escolher o ID:
./scripts/create_firebase_project.sh desafio-familia-silva
```

O script faz login na sua conta Google, cria o projeto, cria o banco Firestore
em `southamerica-east1`, para nos dois ajustes que só o console faz, e no fim
chama o `setup_firebase.sh` para conectar o app e publicar as regras.

**O que ele não consegue fazer** — o Firebase CLI simplesmente não tem comando
para isso, então são dois cliques seus (o script abre os links e espera):

1. **Ativar o login por e-mail/senha** — Authentication → Sign-in method
2. **Criar o bucket do Storage** — Storage → Começar

### Já tenho projeto

```bash
./scripts/setup_firebase.sh meu-projeto-id
```

Antes, confira no console que estão ativados:

| Serviço | Onde | Configuração |
|---|---|---|
| **Authentication** | Build → Authentication → Sign-in method | ative **E-mail/senha** |
| **Cloud Firestore** | Build → Firestore Database → Criar | modo **produção**, `southamerica-east1` |
| **Storage** | Build → Storage → Começar | modo **produção**, mesma região |

> A região do Firestore **não pode ser trocada depois**. `southamerica-east1`
> (São Paulo) corta bem a latência para quem está no Brasil.

### Sobre o Storage e o plano Blaze

Projetos criados recentemente precisam do **plano Blaze** (pagamento por uso)
para usar o Cloud Storage — o bucket gratuito saiu do plano Spark. O Blaze tem
cota gratuita generosa, mas exige cadastrar um cartão.

**A foto comprovante passou a ser obrigatória**, então o Storage virou
dependência real: sem bucket, ninguém consegue registrar atividade.

Se você não vai ativar o Blaze agora, desligue a exigência na família — o resto
do app (cofre, pontos, sequência, cartas, mural) funciona igual, só sem foto:

```dart
context.read<FamilyService>().setRequirePhotoProof(familyId, false);
```

Ou direto no documento da família, no console: `requirePhotoProof: false`.

No emulador local isso não é problema: o Storage emulado sobe junto e aceita
upload sem cobrança nenhuma.

Firestore e Authentication continuam no plano gratuito normalmente.

### Rodar o app

```bash
flutter run
```

## O que o script ajusta no nativo

Duas coisas que o `flutter create` não faz e que quebram o app se ficarem de
fora:

| Ajuste | Onde | Por quê |
|---|---|---|
| `minSdk = 23` | `android/app/build.gradle` | `firebase_auth` 5.x não compila abaixo disso |
| `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` | `ios/Runner/Info.plist` | sem as descrições, o iOS **encerra o app** ao abrir a câmera ou a galeria |

No iOS o script usa o `PlistBuddy` (só existe no macOS). Fora do macOS ele
avisa e mostra o que colar à mão.

---

## Como o app decide onde conectar

Tudo em `lib/core/config/firebase_bootstrap.dart`:

```
USE_FIREBASE_EMULATOR=true  ──▶  emulador local (projeto demo-*, sem credencial)
firebase_options preenchido ──▶  projeto real
placeholders "COLE_..."     ──▶  tela de setup com o passo a passo
```

O terceiro caso é o detalhe que evita a tela branca: em vez de estourar no
`Firebase.initializeApp`, o app abre uma tela explicando o que falta e com os
comandos prontos para copiar.

---

## Publicar só as regras

Depois de mexer em `firestore.rules`, `firestore.indexes.json` ou
`storage.rules`:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Os índices compostos (`familyId` + `createdAt`) levam alguns minutos para
ficarem prontos. Enquanto isso, o mural pode vir vazio.

---

## Quando der errado

| Sintoma | Causa provável |
|---|---|
| Tela de setup mesmo depois do configure | `lib/firebase_options.dart` ainda tem `COLE_` — o configure não concluiu |
| `[cloud_firestore/permission-denied]` | regras não publicadas, ou o perfil sem `familyId` |
| Mural vazio e erro de índice no console | índice composto ainda construindo — o log traz um link que cria o índice |
| `The query requires an index` | rode `firebase deploy --only firestore:indexes` |
| iOS fecha ao tirar foto | faltam as descrições no `Info.plist` (tabela acima) |
| `Default FirebaseApp is not initialized` no Android | falta o `google-services.json` em `android/app/` — o `flutterfire configure` baixa |
| Emulador não sobe | Java ausente: `brew install openjdk` / `sudo apt install default-jre` |
| `projects:create` falha | primeira vez na conta (aceite os termos no console), cota de projetos atingida, ou o ID já existe no mundo — rode de novo para sortear outro |
| Upload de foto falha, resto funciona | bucket do Storage não criado, ou projeto no plano Spark (ver seção do Blaze acima) |

---

## Segurança

`lib/firebase_options.dart`, `google-services.json` e `GoogleService-Info.plist`
carregam a configuração pública do cliente — não são segredo, mas o
`google-services.json` e o `.plist` estão no `.gitignore` porque cada pessoa
gera o seu no `flutterfire configure`.

Quem protege os dados são as **regras** (`firestore.rules` e `storage.rules`):
sem elas publicadas, qualquer um com o ID do projeto lê o cofre da família.
O `setup_firebase.sh` publica as regras no último passo justamente por isso.
