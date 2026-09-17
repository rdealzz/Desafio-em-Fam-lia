import 'package:flutter_test/flutter_test.dart';

import 'package:desafio_em_familia/models/feed_post.dart';
import 'package:desafio_em_familia/services/photo_proof.dart';
import 'package:desafio_em_familia/widgets/ui/feed_photo.dart';

FeedPost _post({
  String id = 'p1',
  String? dados,
  DateTime? vence,
  String? url,
}) =>
    FeedPost(
      id: id,
      familyId: 'f1',
      authorId: 'u1',
      authorName: 'T',
      type: FeedPostType.activity,
      message: 'x',
      photoData: dados,
      photoExpiresAt: vence,
      photoUrl: url,
    );

void main() {
  final ontem = DateTime.now().subtract(const Duration(hours: 25));
  final logo = DateTime.now().add(const Duration(hours: 3));

  group('O que o mural mostra', () {
    test('foto no prazo aparece', () {
      expect(FeedPhoto.para(_post(dados: 'QUJD', vence: logo)), isNotNull);
    });

    test('foto vencida não aparece, mesmo com os bytes ainda no documento', () {
      // A limpeza só roda quando alguém abre o app; até lá, o combinado de um
      // dia tem de valer assim mesmo.
      expect(FeedPhoto.para(_post(dados: 'QUJD', vence: ontem)), isNull);
    });

    test('post sem foto nenhuma não devolve widget', () {
      expect(FeedPhoto.para(_post()), isNull);
    });

    test('registro antigo, com foto no Storage, ainda aparece', () {
      expect(FeedPhoto.para(_post(url: 'https://exemplo/foto.jpg')), isNotNull);
    });

    test('cada post leva chave própria', () {
      // Sem chave, o Flutter reaproveita o estado por posição na lista e uma
      // foto quebrada escondia a foto do post seguinte.
      final a = FeedPhoto.para(_post(id: 'a', dados: 'QUJD', vence: logo));
      final b = FeedPhoto.para(_post(id: 'b', dados: 'QUJD', vence: logo));
      expect(a!.key, isNotNull);
      expect(a.key, isNot(equals(b!.key)));
    });
  });

  group('Prazo', () {
    test('o vencimento é um dia depois', () {
      expect(PhotoProof.validade, const Duration(hours: 24));
    });
  });
}
