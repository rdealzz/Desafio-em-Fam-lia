import '../core/utils/firestore_utils.dart';
import 'activity_type.dart';

/// Registro imutável de uma atividade feita por um membro (`activity_logs`).
///
/// É o histórico auditável: o cofre pode ser recalculado a partir daqui.
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.durationMinutes,
    required this.points,
    this.steps = 0,
    this.basePoints = 0,
    this.stepsPoints = 0,
    this.photoUrl,
    this.note = '',
    this.weekId = '',
    this.source = 'manual',
    this.createdAt,
    this.syncedAt,
  });

  final String id;
  final String familyId;
  final String userId;

  /// Desnormalizado para o feed não precisar de join.
  final String userName;

  final ActivityType type;
  final int durationMinutes;
  final int steps;

  /// Total creditado ao cofre (`basePoints` + `stepsPoints`).
  final int points;
  final int basePoints;
  final int stepsPoints;

  /// Foto comprovante no Firebase Storage.
  final String? photoUrl;
  final String note;
  final String weekId;

  /// `manual` ou `health` (HealthKit / Google Fit).
  final String source;

  /// Quando a atividade foi feita, segundo o aparelho.
  final DateTime? createdAt;

  /// Quando o registro chegou ao servidor, segundo o relógio DO SERVIDOR.
  ///
  /// Guardar os dois lados é o que permite ver um registro atrasado — e é a
  /// hora do servidor que as regras validam, não a do aparelho.
  final DateTime? syncedAt;

  /// Veio da fila offline: ficou um tempo guardado antes de subir.
  bool get isOfflineSync {
    final feito = createdAt;
    final chegou = syncedAt;
    if (feito == null || chegou == null) return false;
    return chegou.difference(feito) > const Duration(minutes: 10);
  }

  /// Quanto tempo o registro esperou para subir.
  Duration? get syncDelay {
    final feito = createdAt;
    final chegou = syncedAt;
    if (feito == null || chegou == null) return null;
    final atraso = chegou.difference(feito);
    return atraso.isNegative ? Duration.zero : atraso;
  }

  factory ActivityLog.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLog(
      id: id,
      familyId: FirestoreUtils.toStringValue(map['familyId']),
      userId: FirestoreUtils.toStringValue(map['userId']),
      userName: FirestoreUtils.toStringValue(map['userName']),
      type: ActivityType.fromId(map['type'] as String?),
      durationMinutes: FirestoreUtils.toInt(map['durationMinutes']),
      steps: FirestoreUtils.toInt(map['steps']),
      points: FirestoreUtils.toInt(map['points']),
      basePoints: FirestoreUtils.toInt(map['basePoints']),
      stepsPoints: FirestoreUtils.toInt(map['stepsPoints']),
      photoUrl: map['photoUrl'] as String?,
      note: FirestoreUtils.toStringValue(map['note']),
      weekId: FirestoreUtils.toStringValue(map['weekId']),
      source: FirestoreUtils.toStringValue(map['source'], fallback: 'manual'),
      createdAt: FirestoreUtils.toDateTime(map['createdAt']),
      syncedAt: FirestoreUtils.toDateTime(map['syncedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'userId': userId,
        'userName': userName,
        'type': type.id,
        'durationMinutes': durationMinutes,
        'steps': steps,
        'points': points,
        'basePoints': basePoints,
        'stepsPoints': stepsPoints,
        'photoUrl': photoUrl,
        'note': note,
        'weekId': weekId,
        'source': source,
        'createdAt': createdAt,
        'syncedAt': syncedAt,
      };
}
