import '../models/app_user.dart';

/// Uma linha do placar da semana.
class Standing {
  const Standing({
    required this.member,
    required this.position,
    required this.share,
    required this.lantern,
  });

  final AppUser member;

  /// 1, 2, 3... Empate divide a posição: dois com 300 pts são ambos 1º.
  final int position;

  /// Fatia do cofre desta semana, de 0.0 a 1.0.
  final double share;

  /// Está na lanterna — a Punição Leve de domingo é dele.
  final bool lantern;

  int get points => member.pointsThisWeek;
}

/// O placar da semana, pronto para a tela de fechamento.
///
/// A graça do app é o cofre ser de todos, então o placar não troca isso por
/// competição: serve para saber quem puxou a semana e quem paga a prenda de
/// domingo. A regra vive aqui, e não na tela, para ser testada.
class WeeklyStandings {
  const WeeklyStandings._(this.rows);

  factory WeeklyStandings.from(List<AppUser> members) {
    final ordenados = [...members]..sort((a, b) {
        final porPontos = b.pointsThisWeek.compareTo(a.pointsThisWeek);
        if (porPontos != 0) return porPontos;
        final porSequencia = b.currentStreak.compareTo(a.currentStreak);
        if (porSequencia != 0) return porSequencia;
        return a.displayName.compareTo(b.displayName);
      });

    final total = ordenados.fold<int>(0, (s, m) => s + m.pointsThisWeek);
    final menor = ordenados.isEmpty ? 0 : ordenados.last.pointsThisWeek;
    final maior = ordenados.isEmpty ? 0 : ordenados.first.pointsThisWeek;
    // Sem lanterna quando todo mundo empatou: não há "quem fez menos".
    final temLanterna = ordenados.length > 1 && menor < maior;

    final rows = <Standing>[];
    for (var i = 0; i < ordenados.length; i++) {
      final m = ordenados[i];
      final empatado =
          i > 0 && ordenados[i - 1].pointsThisWeek == m.pointsThisWeek;
      rows.add(Standing(
        member: m,
        position: empatado ? rows[i - 1].position : i + 1,
        share: total == 0 ? 0 : m.pointsThisWeek / total,
        lantern: temLanterna && m.pointsThisWeek == menor,
      ));
    }
    return WeeklyStandings._(rows);
  }

  final List<Standing> rows;

  bool get isEmpty => rows.isEmpty;

  /// Até três no pódio — só quem pontuou sobe nele.
  List<Standing> get podium => rows.where((r) => r.points > 0).take(3).toList();

  List<Standing> get lantern => rows.where((r) => r.lantern).toList();

  int get totalPoints => rows.fold(0, (s, r) => s + r.points);
}
