# 🏆 Desafio em Família

App de gamificação familiar: quatro pessoas alimentam um **Cofre de Pontos**
coletivo com exercício durante a semana. Bateu a meta, libera o **Prêmio do
Fim de Semana**.

O foco é colaborativo, não competitivo — cada um pontua na sua capacidade e
tudo vai para o mesmo cofre.

**Flutter (Dart) + Firebase** (Authentication, Cloud Firestore, Storage).

---

## Como funciona

### Pontuação

| Modalidade | Regra |
|---|---|
| 🚶 Caminhada | 100 pts a cada 30 min **+ 1 pt a cada 100 passos** |
| 🧘 Alongamento | 50 pts a cada 10 min |
| 🏋️ Academia / Corrida | 150 pts a cada 30 min |
| 🏠 Exercício em Casa | 100 pts a cada 20 min |

Só blocos completos pontuam (45 min de caminhada = 100 pts), e a tela de
registro sempre mostra quanto falta para o próximo bloco. A conta vive em um
lugar só: `lib/services/points_calculator.dart`.

### Cartas de brincadeira

| Carta | O que faz |
|---|---|
| 🦸 **Salva-Mãe / Salva-Pai** | Quem treinou dobrado doa pontos para outro integrante — quem recebe leva o **dobro** e mantém a sequência diária. 1 carta por pessoa por semana. |
| 🔥 **Desafio Impossível** | Mini-desafio relâmpago publicado no mural ("10 polichinelos em vídeo agora vale +50 pts"). |
| 🤡 **Punição Leve** | A prenda de domingo de quem fez menos pontos (lavar a louça, dançar a música escolhida...). |

### Prêmios

- **Nível 1 (semanal):** Noite da Pizza 🍕, Noite dos Jogos 🎲, Domingo do Açaí 🍨
- **Nível 2 (mensal):** passeio em família 🎡

Cada prêmio tem um valor em pontos; quando o cofre passa desse valor, ele
desbloqueia sozinho e vira um aviso no mural.

---

## As 3 telas

| Tela | Arquivo | Conteúdo |
|---|---|---|
| **1. A Casa** (dashboard) | `lib/screens/home/home_screen.dart` | Barra de progresso do cofre, avatares dos 4 com status do dia, botão grande "Registrar Atividade", prêmios e cartas |
| **2. Registrar Atividade** | `lib/screens/activity/register_activity_screen.dart` | Ícones grandes por modalidade, duração, passos, foto comprovante, preview de pontos ao vivo |
| **3. Mural do Deboche & Apoio** | `lib/screens/feed/feed_screen.dart` | Feed privado dos 4, fotos, tempo e pontos, reações por emoji, cartas publicadas |

---

## Estrutura do projeto

```
lib/
├── main.dart                  # bootstrap do Firebase
├── app.dart                   # injeção de dependências + AuthGate
├── firebase_options.dart      # GERADO por `flutterfire configure`
│
├── core/
│   ├── config/
│   │   └── firebase_bootstrap.dart  # produção, emulador ou tela de setup
│   ├── theme/app_theme.dart   # cores, tipografia, botões grandes
│   └── utils/                 # semana ISO, formatação, conversão Firestore
│
├── models/                    # AppUser, Family, Reward, ActivityLog, FeedPost
│
├── services/                  # a lógica de negócio fica toda aqui
│   ├── points_calculator.dart # fonte única das regras de pontuação
│   ├── activity_service.dart  # runTransaction: cofre, sequência, prêmios
│   ├── family_service.dart    # criar/entrar na família, convites
│   ├── feed_service.dart      # mural, reações, cartas
│   ├── auth_service.dart      # login, cadastro
│   ├── storage_service.dart   # upload das fotos
│   └── health_service.dart    # ponte para HealthKit / Google Fit
│
├── state/session_controller.dart  # usuário + família + integrantes em tempo real
├── screens/                   # as 3 telas + login
└── widgets/                   # cofre, avatares, prêmios, post do feed, cartas

scripts/create_firebase_project.sh  # cria o projeto Firebase do zero
scripts/setup_firebase.sh      # liga o app a um projeto Firebase real
scripts/run_emulators.sh       # sobe os emuladores locais
docs/firebase_setup.md         # guia de ligação + solução de problemas
docs/firestore_schema.md       # schema JSON de cada coleção
firestore.rules                # segurança: dados privados da família
storage.rules
test/                          # testes das regras de pontuação e da semana
```

### Por que as escritas passam por transação

Quatro pessoas podem registrar atividade ao mesmo tempo. Se cada app lesse o
cofre e escrevesse o novo total, uma sobrescreveria a outra e pontos sumiriam.

`ActivityService.registerActivity` faz tudo dentro de um `runTransaction`:

1. lê `families/{id}` e `users/{uid}`;
2. **vira a semana** se o cofre ainda aponta para a semana passada (zera o
   cofre e os prêmios — sem precisar de job agendado);
3. calcula pontos, sequência diária e prêmios desbloqueados;
4. grava numa tacada só: o log, o perfil, o cofre e o post do mural.

Se alguém escreveu no meio do caminho, o Firestore repete a operação sozinho.

---

## Rodando o projeto

### Só quero ver funcionando (sem conta Firebase)

Roda contra o Firebase Emulator Suite — Auth, Firestore e Storage locais.
Dá para criar a família, registrar atividade, subir foto e usar as cartas.

```bash
# Terminal 1
./scripts/run_emulators.sh

# Terminal 2
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

Painel dos emuladores em <http://localhost:4000>.

### Ligando no Firebase de verdade

**Não tem projeto ainda?** Um comando cria e liga:

```bash
./scripts/create_firebase_project.sh
```

Ele loga na sua conta Google, cria o projeto, cria o banco Firestore em São
Paulo e chama o setup. Restam dois cliques que o Firebase CLI não cobre —
ativar o login por e-mail/senha e criar o bucket do Storage — e o script abre
os links e espera.

**Já tem projeto?**

```bash
./scripts/setup_firebase.sh meu-projeto-id
```

Ele confere as ferramentas, gera `android/` e `ios/`, roda o
`flutterfire configure`, ajusta a configuração nativa (minSdk 23 e as
permissões de câmera/galeria do iOS) e publica as regras e índices.

3. `flutter run`

Enquanto o Firebase não estiver ligado, o app abre uma **tela de setup** com
os comandos — nunca uma tela branca.

Detalhes e solução de problemas: [`docs/firebase_setup.md`](docs/firebase_setup.md)

### Testes

```bash
flutter test
```

## Primeiro uso, com a família

1. A primeira pessoa cria a conta escolhendo **"Criar família"**.
2. No dashboard, toque em **⋮ → código do convite** e mande no grupo do
   WhatsApp.
3. Os outros três criam conta escolhendo **"Tenho convite"** e colam o código.
4. Ajuste a meta da semana: o padrão é 5.000 pts (≈ 1.250 por pessoa, ou uma
   caminhada de 30 min em 4 dias). Comece mais baixo se for a primeira semana.

---

## Próximos passos

O MVP está fechado e funcional. O que faz sentido vir depois, em ordem:

- [ ] **Contador de passos real** — `HealthService` já tem a interface pronta;
      falta a implementação com o pacote `health` (HealthKit / Google Fit).
- [ ] **Tela de configuração da família** — editar meta semanal e prêmios pelo
      app (hoje `FamilyService.updateWeeklyGoal` / `updateRewards` existem, mas
      sem tela).
- [ ] **Recarga automática das cartas** — hoje `refillSaveCards` é manual;
      vira uma Cloud Function agendada na segunda-feira.
- [ ] **Notificações push** — "faltam 500 pts para a Noite da Pizza 🍕".
- [ ] **Fechamento de domingo** — tela com o ranking da semana e quem paga o
      mico.
- [ ] **Mover a doação para Cloud Function** — hoje um integrante escreve no
      perfil de outro (com campos limitados pelas regras). Numa escala maior,
      isso deve virar servidor. Está marcado como `TODO` em `firestore.rules`.
