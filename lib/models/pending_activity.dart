import 'dart:convert';

import 'activity_type.dart';

/// Uma atividade registrada sem internet, à espera de subir.
///
/// Fica em disco (não só em memória): se o celular for reiniciado no meio da
/// caminhada, o registro continua lá.
class PendingActivity {
  const PendingActivity({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.typeId,
    required this.durationMinutes,
    required this.performedAt,
    this.steps = 0,
    this.note = '',
    this.photoPath,
    this.attempts = 0,
    this.lastError,
  });

  /// Vira o id do documento em `activity_logs` na hora de sincronizar. É por
  /// isso que ele é sorteado aqui e não no servidor: se a mesma pendência for
  /// enviada duas vezes, o segundo envio escreve no mesmo documento e a guarda
  /// de idempotência barra o crédito em dobro.
  final String id;

  final String userId;
  final String familyId;
  final String typeId;
  final int durationMinutes;
  final int steps;
  final String note;

  /// Caminho da foto COPIADA para a pasta do app. A foto original do
  /// image_picker vive em cache temporário, que o sistema pode apagar.
  final String? photoPath;

  /// Quando a atividade foi feita — não quando sincronizou.
  final DateTime performedAt;

  final int attempts;
  final String? lastError;

  ActivityType get type => ActivityType.fromId(typeId);

  /// Pendência velha demais para valer: o cofre daquela semana já fechou e
  /// insistir só gera confusão. A pessoa registra de novo se quiser.
  static const Duration maxAge = Duration(days: 2);

  bool get isExpired => DateTime.now().difference(performedAt) > maxAge;

  PendingActivity copyWith({int? attempts, String? lastError}) {
    return PendingActivity(
      id: id,
      userId: userId,
      familyId: familyId,
      typeId: typeId,
      durationMinutes: durationMinutes,
      steps: steps,
      note: note,
      photoPath: photoPath,
      performedAt: performedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'familyId': familyId,
        'typeId': typeId,
        'durationMinutes': durationMinutes,
        'steps': steps,
        'note': note,
        'photoPath': photoPath,
        'performedAt': performedAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  factory PendingActivity.fromJson(Map<String, dynamic> json) {
    return PendingActivity(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      familyId: json['familyId'] as String? ?? '',
      typeId: json['typeId'] as String? ?? 'walk',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      performedAt:
          DateTime.tryParse(json['performedAt'] as String? ?? '') ??
              DateTime.now(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  static String encodeList(List<PendingActivity> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<PendingActivity> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => PendingActivity.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      // Fila corrompida não pode impedir o app de abrir.
      return const [];
    }
  }
}
