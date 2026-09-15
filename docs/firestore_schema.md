# Modelo de dados — Firestore

Quatro coleções na raiz. Nesta escala (uma família, 4 pessoas) coleções
planas com filtro por `familyId` são mais simples de consultar e proteger do
que subcoleções — e já vêm com os índices prontos em `firestore.indexes.json`.

> Quando o app crescer para muitas famílias, o caminho natural é mover
> `activity_logs` e `feed_posts` para subcoleções de `families/{id}` e tirar
> o campo `familyId` do filtro.

---

## `users/{uid}`

O doc id é o UID do Firebase Authentication.

```json
{
  "familyId": "fam_7Hs2",
  "displayName": "Rosa Maria",
  "email": "rosa@exemplo.com",
  "role": "mae",
  "avatarEmoji": "👩",
  "photoUrl": null,

  "totalPoints": 12450,
  "weeklyPoints": 850,
  "weekId": "2026-W37",

  "currentStreak": 4,
  "longestStreak": 11,
  "saveCards": 1,

  "lastActivityAt": "2026-09-14T08:12:00Z",
  "statusMessage": "Caminhada de 30 min — +100 pts",
  "createdAt": "2026-08-01T10:00:00Z",
  "updatedAt": "2026-09-14T08:12:00Z"
}
```

| Campo | Tipo | Observação |
|---|---|---|
| `weeklyPoints` | int | Parcela do membro no cofre da semana. Só vale se `weekId` for a semana atual — a virada zera na primeira atividade. |
| `weekId` | string | ISO-8601 (`2026-W37`). Evita job agendado para resetar. |
| `saveCards` | int | Cartas "Salva-Mãe/Pai" disponíveis (1 por semana). |
| `lastActivityAt` | timestamp | Base da sequência diária e do status "já treinou hoje". |

Dart: `lib/models/app_user.dart`

---

## `families/{familyId}`

O Cofre de Pontos. Os prêmios ficam embutidos porque são poucos, sempre lidos
junto e mudam de estado na mesma transação que atualiza o cofre.

```json
{
  "name": "Família Silva",
  "inviteCode": "K7M2PQ",
  "memberIds": ["uid1", "uid2", "uid3", "uid4"],

  "weeklyGoal": 5000,
  "vaultPoints": 3200,
  "requirePhotoProof": true,
  "weekId": "2026-W37",
  "weekStartAt": "2026-09-08T00:00:00Z",
  "weekEndAt": "2026-09-14T23:59:59Z",

  "rewards": [
    {
      "id": "pizza",
      "title": "Noite da Pizza",
      "description": "Sexta à noite, pizza por conta do cofre.",
      "emoji": "🍕",
      "requiredPoints": 3000,
      "level": 1,
      "unlocked": true,
      "unlockedAt": "2026-09-12T19:40:00Z"
    }
  ],

  "createdAt": "2026-08-01T10:00:00Z",
  "updatedAt": "2026-09-14T08:12:00Z"
}
```

| Campo | Tipo | Observação |
|---|---|---|
| `vaultPoints` | int | Soma dos pontos dos 4 na semana. Só escrito dentro de `runTransaction`. |
| `weeklyGoal` | int | Meta da semana (padrão 5.000). |
| `inviteCode` | string | 6 caracteres sem ambiguidade (sem O/0, I/1). |
| `requirePhotoProof` | bool | Exige foto comprovante em todo registro. Padrão `true`; ausente também conta como `true`. Barrado na tela, na transação e nas regras. |
| `rewards[].level` | int | 1 = prêmio semanal, 2 = mensal. |

Dart: `lib/models/family.dart` e `lib/models/reward.dart`

---

## `activity_logs/{logId}`

Histórico imutável. É a fonte de verdade: o cofre pode ser recalculado somando
os logs da semana.

```json
{
  "familyId": "fam_7Hs2",
  "userId": "uid1",
  "userName": "Rosa Maria",

  "type": "walk",
  "durationMinutes": 45,
  "steps": 4200,

  "points": 142,
  "basePoints": 100,
  "stepsPoints": 42,

  "photoUrl": "https://firebasestorage.../proofs/uid1/1726300000.jpg",
  "note": "caminhada com a vizinha",
  "weekId": "2026-W37",
  "source": "manual",
  "createdAt": "2026-09-14T08:12:00Z"
}
```

`type` ∈ `walk` | `running` | `cycling` | `gym` | `martial_arts` |
`home_workout` | `stretching`
`source` ∈ `manual` | `health` (HealthKit / Google Fit)

Dart: `lib/models/activity_log.dart`

---

## `feed_posts/{postId}`

O Mural do Deboche & Apoio.

```json
{
  "familyId": "fam_7Hs2",
  "authorId": "uid1",
  "authorName": "Rosa Maria",
  "authorAvatar": "👩",
  "authorPhotoUrl": null,

  "type": "activity",
  "message": "🚶 Caminhada — 45 min",
  "photoUrl": "https://firebasestorage.../1726300000.jpg",
  "points": 142,
  "durationMinutes": 45,
  "activityLogId": "log_abc",

  "reactions": {
    "fire": ["uid2", "uid3"],
    "laugh": ["uid4"]
  },

  "metadata": { "activityType": "walk", "steps": 4200, "streak": 4 },
  "createdAt": "2026-09-14T08:12:00Z"
}
```

`type` ∈ `activity` | `save_card` | `impossible_challenge` | `punishment` |
`reward_unlocked` | `system`

As chaves de `reactions` são slugs ASCII (`fire`, `muscle`, `clap`, `laugh`,
`heart`) — emoji direto quebraria o caminho de campo usado no
`arrayUnion`/`arrayRemove`.

Dart: `lib/models/feed_post.dart`

---

## Regras de pontuação

| Modalidade | `type` | Regra |
|---|---|---|
| 🚶 Caminhada | `walk` | 100 pts a cada 30 min **+ 1 pt a cada 100 passos** |
| 🏃 Corrida | `running` | 150 pts a cada 30 min **+ 1 pt a cada 100 passos** |
| 🚴 Ciclismo | `cycling` | 150 pts a cada 30 min |
| 🏋️ Academia | `gym` | 150 pts a cada 30 min |
| 🥋 Luta | `martial_arts` | 150 pts a cada 30 min |
| 🏠 Exercício em Casa | `home_workout` | 100 pts a cada 20 min |
| 🧘 Alongamento | `stretching` | 50 pts a cada 10 min |

Só blocos completos pontuam: 45 min de caminhada = 1 bloco = 100 pts (a tela
avisa quanto falta para o próximo). Implementação única em
`lib/services/points_calculator.dart` — a interface e a transação usam a mesma
função, então o preview nunca diverge do que é gravado.

**Carta Salva-Mãe/Pai:** o doador gasta `N` pontos da semana, quem recebe ganha
`2N` e mantém a sequência. Efeito no cofre: `+N` (os `N` do doador já estavam
lá; entram `2N`).

---

## Escritas atômicas

| Operação | Onde | O que trava |
|---|---|---|
| Registrar atividade | `ActivityService.registerActivity` | lê `families/{id}` + `users/{uid}`, grava log, perfil, cofre e post do mural numa transação |
| Doar pontos (Salva-Mãe/Pai) | `ActivityService.donatePoints` | lê doador, recebedor e família; move os pontos e publica a carta |
| Reagir a um post | `FeedService.toggleReaction` | `arrayUnion`/`arrayRemove` resolvem no servidor, sem transação |

A virada de semana acontece dentro da própria transação: se `weekId` do cofre
for de uma semana anterior, ele zera antes de somar. Nenhum Cloud Scheduler
necessário no MVP.
