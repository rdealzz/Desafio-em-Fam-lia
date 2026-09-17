import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log.dart';
import '../models/feed_post.dart';
import 'firestore_refs.dart';
import 'photo_proof.dart';

/// Apaga do Firestore as fotos que passaram do prazo de um dia.
///
/// Sem plano pago não há Cloud Function nem tarefa agendada, então quem limpa
/// é o próprio app: cada vez que alguém abre o mural, as fotos vencidas que
/// estão ali na tela são apagadas. Com quatro pessoas abrindo o app todo dia,
/// isso cobre de sobra — e se ninguém abrir, também não há ninguém para quem a
/// foto esteja exposta.
///
/// Limpa só o que já está carregado na tela, de propósito: uma consulta por
/// `photoExpiresAt` exigiria mais um índice composto, e índice é justamente o
/// que este projeto não consegue criar sozinho.
class PhotoCleanupService {
  PhotoCleanupService(this._refs);

  final FirestoreRefs _refs;

  /// Evita repetir a escrita enquanto a anterior não voltou — o stream do
  /// Firestore reemite a lista a cada mudança, inclusive as desta limpeza.
  bool _limpando = false;

  /// Só os campos da foto vão a zero. Pontos, hora e tipo continuam
  /// intocados: o histórico é imutável, a foto é a exceção combinada.
  static const Map<String, Object?> _zerado = {
    'photoData': null,
    'photoExpiresAt': null,
  };

  Future<void> limpar({
    List<FeedPost> posts = const [],
    List<ActivityLog> logs = const [],
  }) async {
    if (_limpando) return;

    final alvos = <DocumentReference<Map<String, dynamic>>>[];
    for (final post in posts) {
      if (post.photoData != null && PhotoProof.venceu(post.photoExpiresAt)) {
        alvos.add(_refs.feedPosts.doc(post.id));
      }
    }
    for (final log in logs) {
      if (log.photoData != null && PhotoProof.venceu(log.photoExpiresAt)) {
        alvos.add(_refs.activityLogs.doc(log.id));
      }
    }
    if (alvos.isEmpty) return;

    _limpando = true;
    try {
      final batch = _refs.db.batch();
      for (final ref in alvos) {
        batch.update(ref, _zerado);
      }
      await batch.commit();
    } catch (_) {
      // Limpeza é oportunista: se falhar, a próxima abertura tenta de novo.
      // Enquanto isso a foto já não aparece — quem esconde é FeedPhoto.para,
      // que olha o vencimento antes dos bytes.
    } finally {
      _limpando = false;
    }
  }
}
