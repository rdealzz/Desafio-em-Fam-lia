import '../core/utils/firestore_utils.dart';
import '../core/utils/week_utils.dart';
import 'reward.dart';

/// O grupo familiar e seu Cofre de Pontos semanal (coleção `families`).
class Family {
  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.memberIds = const [],
    this.weeklyGoal = 5000,
    this.vaultPoints = 0,
    this.weekId = '',
    this.weekStartAt,
    this.weekEndAt,
    this.rewards = const [],
    this.createdAt,
  });

  final String id;
  final String name;

  /// Código curto que os outros 3 integrantes digitam para entrar.
  final String inviteCode;

  final List<String> memberIds;

  /// Meta do cofre da semana (padrão: 5.000 pontos).
  final int weeklyGoal;

  /// Pontos já depositados no cofre nesta semana.
  final int vaultPoints;

  final String weekId;
  final DateTime? weekStartAt;
  final DateTime? weekEndAt;

  final List<Reward> rewards;
  final DateTime? createdAt;

  /// 0.0 a 1.0 — pronto para alimentar a ProgressBar do dashboard.
  double get progress {
    if (weeklyGoal <= 0) return 0;
    return (vaultPoints / weeklyGoal).clamp(0.0, 1.0);
  }

  int get pointsRemaining => (weeklyGoal - vaultPoints).clamp(0, weeklyGoal);

  bool get goalReached => vaultPoints >= weeklyGoal;

  /// True quando o cofre ainda aponta para uma semana anterior — o próximo
  /// registro de atividade faz a virada (ver `ActivityService`).
  bool get needsWeeklyReset => weekId != WeekUtils.currentWeekId();

  List<Reward> get unlockedRewards =>
      rewards.where((reward) => reward.unlocked).toList();

  /// Próximo prêmio a ser desbloqueado, ou null se todos já caíram.
  Reward? get nextReward {
    final pending = rewards.where((r) => !r.unlocked).toList()
      ..sort((a, b) => a.requiredPoints.compareTo(b.requiredPoints));
    return pending.isEmpty ? null : pending.first;
  }

  factory Family.fromMap(String id, Map<String, dynamic> map) {
    final rawRewards = map['rewards'];
    return Family(
      id: id,
      name: FirestoreUtils.toStringValue(map['name'], fallback: 'Família'),
      inviteCode: FirestoreUtils.toStringValue(map['inviteCode']),
      memberIds: FirestoreUtils.toStringList(map['memberIds']),
      weeklyGoal: FirestoreUtils.toInt(map['weeklyGoal'], fallback: 5000),
      vaultPoints: FirestoreUtils.toInt(map['vaultPoints']),
      weekId: FirestoreUtils.toStringValue(map['weekId']),
      weekStartAt: FirestoreUtils.toDateTime(map['weekStartAt']),
      weekEndAt: FirestoreUtils.toDateTime(map['weekEndAt']),
      rewards: rawRewards is List
          ? rawRewards
              .map((e) => Reward.fromMap(FirestoreUtils.toMap(e)))
              .toList()
          : const <Reward>[],
      createdAt: FirestoreUtils.toDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'inviteCode': inviteCode,
        'memberIds': memberIds,
        'weeklyGoal': weeklyGoal,
        'vaultPoints': vaultPoints,
        'weekId': weekId,
        'weekStartAt': weekStartAt,
        'weekEndAt': weekEndAt,
        'rewards': rewards.map((r) => r.toMap()).toList(),
        'createdAt': createdAt,
      };
}
