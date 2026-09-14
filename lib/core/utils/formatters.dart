import 'package:intl/intl.dart';

/// Formatações usadas na interface (pontos, duração, tempo relativo).
class Formatters {
  const Formatters._();

  static final NumberFormat _points = NumberFormat.decimalPattern('pt_BR');

  /// 3200 -> "3.200"
  static String points(int value) => _points.format(value);

  /// 95 -> "1h35"
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h${rest.toString().padLeft(2, '0')}';
  }

  /// "agora", "há 5 min", "há 3 h", "ontem", "12/09"
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return DateFormat('dd/MM').format(date);
  }

  static String dayLabel(DateTime date) =>
      DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(date);
}
