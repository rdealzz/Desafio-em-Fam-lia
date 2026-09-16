import '../models/activity_log.dart';
import '../models/activity_type.dart';
import '../models/app_user.dart';
import '../models/family.dart';
import '../models/feed_post.dart';
import '../models/reward.dart';
import '../core/utils/week_utils.dart';

/// Dados de mentira para a vitrine do app.
///
/// Servem para ver a interface funcionando sem Firebase nenhum — é o que a
/// página publicada mostra. Nada aqui vai para servidor algum.
class DemoData {
  const DemoData._();

  static final DateTime _agora = DateTime.now();

  static DateTime _horasAtras(int h) => _agora.subtract(Duration(hours: h));
  static DateTime _diasAtras(int d) => _agora.subtract(Duration(days: d));

  static const String familyId = 'demo_familia';

  static final AppUser eu = AppUser(
    id: 'demo_filho',
      username: 'rafael',
      avatarColor: 0xFF2E90FA,
    familyId: familyId,
    displayName: 'Rafael',
    role: 'filho',
    avatarEmoji: '😎',
    totalPoints: 8420,
    weeklyPoints: 1150,
    weekId: WeekUtils.currentWeekId(),
    currentStreak: 5,
    longestStreak: 12,
    saveCards: 1,
    lastActivityAt: _horasAtras(3),
    statusMessage: 'Corrida · 30 min',
  );

  static final List<AppUser> membros = [
    eu,
    AppUser(
      id: 'demo_mae',
      username: 'rosa.maria',
      avatarColor: 0xFFDB2777,
      familyId: familyId,
      displayName: 'Rosa Maria',
      role: 'mae',
      avatarEmoji: '👩',
      totalPoints: 9610,
      weeklyPoints: 1300,
      weekId: WeekUtils.currentWeekId(),
      currentStreak: 7,
      longestStreak: 19,
      saveCards: 1,
      lastActivityAt: _horasAtras(6),
      statusMessage: 'Caminhada · 45 min',
    ),
    AppUser(
      id: 'demo_pai',
      username: 'antonio',
      avatarColor: 0xFF12A366,
      familyId: familyId,
      displayName: 'Antônio',
      role: 'pai',
      avatarEmoji: '🧔',
      totalPoints: 6180,
      weeklyPoints: 450,
      weekId: WeekUtils.currentWeekId(),
      currentStreak: 0,
      longestStreak: 8,
      saveCards: 1,
      lastActivityAt: _diasAtras(2),
      statusMessage: 'Faltam 1.000 passos',
    ),
    AppUser(
      id: 'demo_nora',
      username: 'julia',
      avatarColor: 0xFF8B5CF6,
      familyId: familyId,
      displayName: 'Júlia',
      role: 'membro',
      avatarEmoji: '🦸',
      totalPoints: 7340,
      weeklyPoints: 300,
      weekId: WeekUtils.currentWeekId(),
      currentStreak: 2,
      longestStreak: 10,
      saveCards: 0,
      lastActivityAt: _horasAtras(20),
      statusMessage: 'Alongamento · 20 min',
    ),
  ];

  static final Family familia = Family(
    id: familyId,
    name: 'Família Silva',
    inviteCode: 'K7M2PQ',
    memberIds: membros.map((m) => m.id).toList(),
    weeklyGoal: 5000,
    vaultPoints: 3200,
    weekId: WeekUtils.currentWeekId(),
    weekStartAt: WeekUtils.startOfWeek(_agora),
    weekEndAt: WeekUtils.endOfWeek(_agora),
    rewards: [
      const Reward(
        id: 'pizza',
        title: 'Noite da Pizza',
        description: 'Sexta à noite, pizza por conta do cofre.',
        emoji: '🍕',
        requiredPoints: 3000,
        unlocked: true,
      ),
      const Reward(
        id: 'board_games',
        title: 'Noite dos Jogos',
        description: 'Tabuleiro e bagunça no sábado.',
        emoji: '🎲',
        requiredPoints: 4000,
      ),
      const Reward(
        id: 'acai',
        title: 'Domingo do Açaí',
        description: 'Meta batida = açaí para os quatro.',
        emoji: '🍨',
        requiredPoints: 5000,
      ),
      const Reward(
        id: 'family_outing',
        title: 'Passeio em Família',
        description: 'Prêmio mensal: parque, cinema ou café da manhã fora.',
        emoji: '🎡',
        requiredPoints: 20000,
        level: 2,
      ),
    ],
  );

  /// Histórico espalhado pelos últimos dias, para o strip de 7 dias ter forma.
  static List<ActivityLog> logsDe(String userId) {
    final base = <(ActivityType, int, int)>[
      (ActivityType.running, 30, 0),
      (ActivityType.walk, 45, 4200),
      (ActivityType.gym, 60, 0),
      (ActivityType.stretching, 20, 0),
      (ActivityType.cycling, 90, 0),
      (ActivityType.homeWorkout, 40, 0),
      (ActivityType.martialArts, 60, 0),
    ];

    return List.generate(base.length, (i) {
      final (tipo, minutos, passos) = base[i];
      final quando = _diasAtras(i).subtract(Duration(hours: i * 2));
      final blocos = minutos ~/ tipo.blockMinutes;
      final pontos = blocos * tipo.blockPoints + passos ~/ 100;
      return ActivityLog(
        id: 'demo_log_${userId}_$i',
        familyId: familyId,
        userId: userId,
        userName: membros.firstWhere((m) => m.id == userId).displayName,
        type: tipo,
        durationMinutes: minutos,
        steps: passos,
        points: pontos,
        basePoints: blocos * tipo.blockPoints,
        stepsPoints: passos ~/ 100,
        weekId: WeekUtils.weekId(quando),
        createdAt: quando,
        syncedAt: i == 4 ? quando.add(const Duration(hours: 5)) : quando,
      );
    });
  }

  static List<FeedPost> get feed => [
        FeedPost(
          id: 'demo_post_1',
          familyId: familyId,
          authorId: 'demo_mae',
          authorName: 'Rosa Maria',
          authorAvatar: '👩',
          type: FeedPostType.activity,
          message: 'Caminhada — 45 min. Fui até a padaria e voltei andando!',
          points: 142,
          durationMinutes: 45,
          metadata: const {'activityType': 'walk', 'steps': 4200, 'streak': 7},
          reactions: const {
            'fire': ['demo_filho', 'demo_pai'],
            'clap': ['demo_nora'],
          },
          createdAt: _horasAtras(6),
        ),
        FeedPost(
          id: 'demo_post_2',
          familyId: familyId,
          authorId: 'demo_filho',
          authorName: 'Rafael',
          authorAvatar: '😎',
          type: FeedPostType.activity,
          message: 'Corrida — 30 min',
          points: 150,
          durationMinutes: 30,
          metadata: {
            'activityType': 'running',
            'streak': 5,
            'offlineSync': true,
            'performedAt': _horasAtras(9),
          },
          reactions: const {
            'muscle': ['demo_mae'],
          },
          createdAt: _horasAtras(3),
        ),
        FeedPost(
          id: 'demo_post_3',
          familyId: familyId,
          authorId: 'demo_nora',
          authorName: 'Júlia',
          authorAvatar: '🦸',
          type: FeedPostType.impossibleChallenge,
          message: 'Quem fizer 10 polichinelos em vídeo agora ganha +50 pts',
          reactions: const {
            'laugh': ['demo_filho', 'demo_mae', 'demo_pai'],
          },
          createdAt: _horasAtras(11),
        ),
        FeedPost(
          id: 'demo_post_4',
          familyId: familyId,
          authorId: 'system',
          authorName: 'Família Silva',
          authorAvatar: '🎉',
          type: FeedPostType.rewardUnlocked,
          message: 'Prêmio liberado: Noite da Pizza! '
              'O cofre chegou a 3000 pontos.',
          reactions: const {
            'heart': ['demo_mae', 'demo_nora', 'demo_filho'],
          },
          createdAt: _horasAtras(14),
        ),
        FeedPost(
          id: 'demo_post_5',
          familyId: familyId,
          authorId: 'demo_filho',
          authorName: 'Rafael',
          authorAvatar: '😎',
          type: FeedPostType.saveCard,
          message: 'Carta Salva-Mãe/Pai! Rafael treinou em dobro e doou '
              '100 pts — Antônio recebeu 200 pts e manteve a sequência.',
          points: 200,
          metadata: const {'toUserName': 'Antônio', 'donatedPoints': 100},
          reactions: const {
            'clap': ['demo_pai', 'demo_mae'],
          },
          createdAt: _diasAtras(1),
        ),
        FeedPost(
          id: 'demo_post_6',
          familyId: familyId,
          authorId: 'demo_pai',
          authorName: 'Antônio',
          authorAvatar: '🧔',
          type: FeedPostType.activity,
          message: 'Ciclismo — 90 min. Pedalei até a represa',
          points: 450,
          durationMinutes: 90,
          metadata: const {'activityType': 'cycling'},
          reactions: const {
            'fire': ['demo_mae'],
            'muscle': ['demo_filho', 'demo_nora'],
          },
          createdAt: _diasAtras(2),
        ),
      ];
}
