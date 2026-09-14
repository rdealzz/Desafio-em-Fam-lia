import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/feed_post.dart';
import 'firestore_refs.dart';

/// Mural do Deboche & Apoio: leitura do feed, reações e cartas de brincadeira.
class FeedService {
  FeedService(this._refs);

  final FirestoreRefs _refs;

  Stream<List<FeedPost>> watchFeed(String familyId, {int limit = 50}) {
    return _refs.feedPosts
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeedPost.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Liga/desliga a reação do usuário. `arrayUnion`/`arrayRemove` resolvem a
  /// concorrência no servidor — não precisa de transação aqui.
  Future<void> toggleReaction({
    required String postId,
    required String reactionKey,
    required String userId,
    required bool isActive,
  }) {
    final field = 'reactions.$reactionKey';
    return _refs.feedPosts.doc(postId).update({
      field: isActive
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }

  /// Publica uma Carta de Desafio Impossível ou de Punição Leve.
  Future<void> publishCard({
    required AppUser author,
    required FeedPostType type,
    required String message,
    Map<String, dynamic> metadata = const {},
  }) {
    final ref = _refs.feedPosts.doc();
    return ref.set({
      ...FeedPost(
        id: ref.id,
        familyId: author.familyId,
        authorId: author.id,
        authorName: author.displayName,
        authorAvatar: author.avatarEmoji,
        authorPhotoUrl: author.photoUrl,
        type: type,
        message: message,
        metadata: metadata,
      ).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cartas ativas (desafios e punições das últimas 24h) para o aviso do topo.
  Stream<List<FeedPost>> watchActiveCards(String familyId) {
    final since = DateTime.now().subtract(const Duration(hours: 24));
    return _refs.feedPosts
        .where('familyId', isEqualTo: familyId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeedPost.fromMap(doc.id, doc.data()))
            .where((post) => post.isCard)
            .toList());
  }

  Future<void> deletePost(String postId) =>
      _refs.feedPosts.doc(postId).delete();
}
