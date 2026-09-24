import 'package:desafio_em_familia/models/feed_post.dart';
import 'package:desafio_em_familia/services/feed_grouping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

FeedPost post(
  String id,
  DateTime? quando, {
  FeedPostType tipo = FeedPostType.activity,
  int pontos = 100,
  int minutos = 30,
}) =>
    FeedPost(
      id: id,
      familyId: 'f',
      authorId: 'a',
      authorName: 'Ana',
      type: tipo,
      points: pontos,
      durationMinutes: minutos,
      createdAt: quando,
    );

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  // Quinta-feira, 24/09/2026, fim da tarde.
  final agora = DateTime(2026, 9, 24, 18);

  group('FeedGrouping.porDia', () {
    test('agrupa por dia com rótulos Hoje, Ontem e a data', () {
      final dias = FeedGrouping.porDia([
        post('1', null), // acabou de ser escrito, sem hora do servidor
        post('2', DateTime(2026, 9, 24, 7)),
        post('3', DateTime(2026, 9, 23, 20)),
        post('4', DateTime(2026, 9, 21, 9)),
      ], agora);

      expect(dias.map((d) => d.rotulo),
          ['Hoje', 'Ontem', 'segunda-feira, 21 de setembro']);
      expect(dias.first.posts.map((p) => p.id), ['1', '2']);
    });

    test('ano diferente mostra o ano', () {
      expect(
        FeedGrouping.rotuloDoDia(DateTime(2025, 12, 31), agora),
        '31 de dezembro de 2025',
      );
    });

    test('lista vazia não tem dias', () {
      expect(FeedGrouping.porDia(const [], agora), isEmpty);
    });
  });

  test('filtros separam treinos do resto', () {
    final treino = post('t', agora);
    final carta = post('c', agora, tipo: FeedPostType.punishment);
    final premio = post('p', agora, tipo: FeedPostType.rewardUnlocked);

    expect(FiltroMural.todos.aceita(carta), isTrue);
    expect(FiltroMural.treinos.aceita(treino), isTrue);
    expect(FiltroMural.treinos.aceita(carta), isFalse);
    expect(FiltroMural.cartas.aceita(premio), isTrue);
    expect(FiltroMural.cartas.aceita(treino), isFalse);
  });

  test('resumo de hoje soma só os treinos do dia', () {
    final r = FeedGrouping.resumoDeHoje([
      post('1', DateTime(2026, 9, 24, 7), pontos: 150, minutos: 30),
      post('2', null, pontos: 100, minutos: 40),
      post('3', DateTime(2026, 9, 23, 7), pontos: 999),
      post('4', agora, tipo: FeedPostType.punishment, pontos: 0),
    ], agora);
    expect(r.treinos, 2);
    expect(r.minutos, 70);
    expect(r.pontos, 250);
  });
}
