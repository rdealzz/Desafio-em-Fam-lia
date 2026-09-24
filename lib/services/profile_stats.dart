import '../core/utils/week_utils.dart';
import '../models/activity_log.dart';
import '../models/activity_type.dart';

/// Quanto uma pessoa fez numa modalidade.
class ResumoModalidade {
  const ResumoModalidade({
    required this.tipo,
    required this.vezes,
    required this.minutos,
    required this.pontos,
  });

  final ActivityType tipo;
  final int vezes;
  final int minutos;
  final int pontos;
}

/// Um dia do histórico, com o rótulo e o total.
class DiaDoHistorico {
  const DiaDoHistorico(this.dia, this.logs);

  final DateTime dia;
  final List<ActivityLog> logs;

  int get pontos => logs.fold(0, (s, l) => s + l.points);
}

/// As contas da tela de perfil, fora da tela para dar para testar.
///
/// Tudo sai dos registros que a tela já carrega (os últimos 60): nenhuma
/// consulta nova ao Firestore.
class ProfileStats {
  const ProfileStats._();

  /// Modalidades da pessoa, da que mais rendeu pontos para a que menos.
  static List<ResumoModalidade> porModalidade(List<ActivityLog> logs) {
    final acc = <ActivityType, List<int>>{};
    for (final l in logs) {
      final a = acc.putIfAbsent(l.type, () => [0, 0, 0]);
      a[0]++;
      a[1] += l.durationMinutes;
      a[2] += l.points;
    }
    final lista = [
      for (final e in acc.entries)
        ResumoModalidade(
          tipo: e.key,
          vezes: e.value[0],
          minutos: e.value[1],
          pontos: e.value[2],
        ),
    ]..sort((a, b) {
        final p = b.pontos.compareTo(a.pontos);
        return p != 0 ? p : b.vezes.compareTo(a.vezes);
      });
    return lista;
  }

  /// Minutos de exercício na semana de [agora].
  static int minutosDaSemana(List<ActivityLog> logs, DateTime agora) {
    final semana = WeekUtils.weekId(agora);
    return logs
        .where((l) =>
            l.createdAt != null && WeekUtils.weekId(l.createdAt!) == semana)
        .fold(0, (s, l) => s + l.durationMinutes);
  }

  /// Registros agrupados por dia, na ordem em que chegaram (mais novo antes).
  static List<DiaDoHistorico> porDia(List<ActivityLog> logs) {
    final dias = <DiaDoHistorico>[];
    for (final l in logs) {
      final at = l.createdAt;
      if (at == null) continue;
      final dia = DateTime(at.year, at.month, at.day);
      if (dias.isEmpty || dias.last.dia != dia) {
        dias.add(DiaDoHistorico(dia, []));
      }
      dias.last.logs.add(l);
    }
    return dias;
  }
}
