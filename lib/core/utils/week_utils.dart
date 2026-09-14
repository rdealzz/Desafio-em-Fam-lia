/// Utilitários de semana. O cofre da família é semanal e zera toda segunda-feira.
class WeekUtils {
  const WeekUtils._();

  /// Segunda-feira 00:00 da semana da data informada.
  static DateTime startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// Domingo 23:59:59 da semana da data informada.
  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date)
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1));
  }

  /// Identificador estável da semana no padrão ISO-8601: `2026-W37`.
  ///
  /// Usado para saber se o cofre (ou a pontuação de um membro) precisa ser
  /// zerado antes de somar a atividade nova.
  static String weekId(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    // A quinta-feira da semana define a qual ano/semana ela pertence.
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final week = ((thursday.difference(firstDayOfYear).inDays) ~/ 7) + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  static String currentWeekId() => weekId(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isYesterday(DateTime date, DateTime reference) {
    final yesterday = DateTime(reference.year, reference.month, reference.day)
        .subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
}
