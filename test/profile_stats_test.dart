import 'package:desafio_em_familia/models/activity_log.dart';
import 'package:desafio_em_familia/models/activity_type.dart';
import 'package:desafio_em_familia/services/profile_stats.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityLog log(ActivityType tipo, int min, int pts, DateTime? quando) =>
    ActivityLog(
      id: '$tipo$min$quando',
      familyId: 'f',
      userId: 'u',
      userName: 'Ana',
      type: tipo,
      durationMinutes: min,
      points: pts,
      createdAt: quando,
    );

void main() {
  // Quinta-feira, 24/09/2026.
  final agora = DateTime(2026, 9, 24, 18);

  test('resumo por modalidade ordena pelos pontos', () {
    final r = ProfileStats.porModalidade([
      log(ActivityType.walk, 30, 100, agora),
      log(ActivityType.gym, 60, 300, agora),
      log(ActivityType.walk, 45, 100, agora),
    ]);
    expect(r.map((m) => m.tipo), [ActivityType.gym, ActivityType.walk]);
    expect(r.last.vezes, 2);
    expect(r.last.minutos, 75);
    expect(r.last.pontos, 200);
  });

  test('minutos da semana ignoram a semana passada', () {
    final m = ProfileStats.minutosDaSemana([
      log(ActivityType.walk, 30, 100, DateTime(2026, 9, 21, 8)), // segunda
      log(ActivityType.walk, 40, 100, DateTime(2026, 9, 20, 8)), // domingo antes
      log(ActivityType.walk, 10, 0, null),
    ], agora);
    expect(m, 30);
  });

  test('histórico agrupa por dia e soma os pontos', () {
    final dias = ProfileStats.porDia([
      log(ActivityType.walk, 30, 100, DateTime(2026, 9, 24, 18)),
      log(ActivityType.gym, 30, 150, DateTime(2026, 9, 24, 7)),
      log(ActivityType.walk, 30, 100, DateTime(2026, 9, 22, 7)),
    ]);
    expect(dias.length, 2);
    expect(dias.first.pontos, 250);
    expect(dias.last.dia, DateTime(2026, 9, 22));
  });
}
