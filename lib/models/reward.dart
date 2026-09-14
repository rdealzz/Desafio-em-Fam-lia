import '../core/utils/firestore_utils.dart';

/// Prêmio do fim de semana, guardado embutido no documento da família.
///
/// Nível 1 (semanal): Noite da Pizza, Jogos de Tabuleiro, Domingo do Açaí.
/// Nível 2 (mensal): passeio no parque, café da manhã fora, cinema em família.
class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.requiredPoints,
    this.description = '',
    this.emoji = '🎁',
    this.level = 1,
    this.unlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;

  /// Pontos do cofre necessários para liberar o prêmio.
  final int requiredPoints;

  /// 1 = prêmio semanal, 2 = prêmio mensal.
  final int level;

  final bool unlocked;
  final DateTime? unlockedAt;

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: FirestoreUtils.toStringValue(map['id']),
      title: FirestoreUtils.toStringValue(map['title'], fallback: 'Prêmio'),
      description: FirestoreUtils.toStringValue(map['description']),
      emoji: FirestoreUtils.toStringValue(map['emoji'], fallback: '🎁'),
      requiredPoints: FirestoreUtils.toInt(map['requiredPoints']),
      level: FirestoreUtils.toInt(map['level'], fallback: 1),
      unlocked: map['unlocked'] == true,
      unlockedAt: FirestoreUtils.toDateTime(map['unlockedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'requiredPoints': requiredPoints,
        'level': level,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt,
      };

  Reward copyWith({bool? unlocked, DateTime? unlockedAt}) => Reward(
        id: id,
        title: title,
        description: description,
        emoji: emoji,
        requiredPoints: requiredPoints,
        level: level,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  /// Prêmios sugeridos ao criar uma família nova. A família edita depois.
  static List<Reward> defaults(int weeklyGoal) => [
        Reward(
          id: 'pizza',
          title: 'Noite da Pizza',
          description: 'Sexta à noite, pizza por conta do cofre.',
          emoji: '🍕',
          requiredPoints: (weeklyGoal * 0.6).round(),
        ),
        Reward(
          id: 'board_games',
          title: 'Noite dos Jogos',
          description: 'Tabuleiro e bagunça no sábado.',
          emoji: '🎲',
          requiredPoints: (weeklyGoal * 0.8).round(),
        ),
        Reward(
          id: 'acai',
          title: 'Domingo do Açaí',
          description: 'Meta batida = açaí para os quatro.',
          emoji: '🍨',
          requiredPoints: weeklyGoal,
        ),
        Reward(
          id: 'family_outing',
          title: 'Passeio em Família',
          description: 'Prêmio mensal: parque, cinema ou café da manhã fora.',
          emoji: '🎡',
          requiredPoints: weeklyGoal * 4,
          level: 2,
        ),
      ];
}
