import 'package:intl/intl.dart';

import '../core/utils/week_utils.dart';
import '../models/feed_post.dart';

/// O que o mural mostra: tudo, só os treinos ou só as cartas.
enum FiltroMural {
  todos('Tudo'),
  treinos('Treinos'),
  cartas('Cartas');

  const FiltroMural(this.rotulo);

  final String rotulo;

  bool aceita(FeedPost post) => switch (this) {
        FiltroMural.todos => true,
        FiltroMural.treinos => post.type == FeedPostType.activity,
        // Aviso de prêmio vai junto das cartas: é o "resto" que não é treino.
        FiltroMural.cartas => post.type != FeedPostType.activity,
      };
}

/// Um dia do mural, com o rótulo que aparece acima das publicações.
class DiaDoMural {
  const DiaDoMural(this.rotulo, this.posts);

  final String rotulo;
  final List<FeedPost> posts;
}

/// Resumo do dia para o topo do mural.
class ResumoDoDia {
  const ResumoDoDia({
    required this.treinos,
    required this.minutos,
    required this.pontos,
  });

  final int treinos;
  final int minutos;
  final int pontos;
}

/// Regras de organização do mural, fora da tela para dar para testar.
class FeedGrouping {
  const FeedGrouping._();

  /// Separa os posts (já em ordem decrescente) por dia.
  ///
  /// Post sem `createdAt` é o que acabou de ser escrito e ainda espera a hora
  /// do servidor: entra em "Hoje", que é quando ele aconteceu.
  static List<DiaDoMural> porDia(List<FeedPost> posts, DateTime agora) {
    final dias = <DiaDoMural>[];
    DateTime? diaAtual;
    for (final post in posts) {
      final quando = post.createdAt ?? agora;
      final dia = DateTime(quando.year, quando.month, quando.day);
      if (diaAtual == null || dia != diaAtual) {
        diaAtual = dia;
        dias.add(DiaDoMural(rotuloDoDia(dia, agora), []));
      }
      dias.last.posts.add(post);
    }
    return dias;
  }

  /// "Hoje", "Ontem", "segunda, 22 de setembro".
  static String rotuloDoDia(DateTime dia, DateTime agora) {
    if (WeekUtils.isSameDay(dia, agora)) return 'Hoje';
    if (WeekUtils.isYesterday(dia, agora)) return 'Ontem';
    final formato = dia.year == agora.year
        ? DateFormat("EEEE, d 'de' MMMM", 'pt_BR')
        : DateFormat("d 'de' MMMM 'de' y", 'pt_BR');
    return formato.format(dia);
  }

  /// Quantos treinos, minutos e pontos a família fez hoje.
  static ResumoDoDia resumoDeHoje(List<FeedPost> posts, DateTime agora) {
    var treinos = 0, minutos = 0, pontos = 0;
    for (final post in posts) {
      if (post.type != FeedPostType.activity) continue;
      if (!WeekUtils.isSameDay(post.createdAt ?? agora, agora)) continue;
      treinos++;
      minutos += post.durationMinutes;
      pontos += post.points;
    }
    return ResumoDoDia(treinos: treinos, minutos: minutos, pontos: pontos);
  }
}
