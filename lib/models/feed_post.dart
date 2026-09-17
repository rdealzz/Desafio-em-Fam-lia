import '../core/utils/firestore_utils.dart';

/// Tipos de publicação do Mural do Deboche & Apoio.
enum FeedPostType {
  /// Atividade registrada por um membro (com foto, tempo e pontos).
  activity('activity', '💪'),

  /// Carta "Salva-Mãe/Pai": doação de pontos em dobro.
  saveCard('save_card', '🦸'),

  /// Carta de Desafio Impossível lançada ao grupo.
  impossibleChallenge('impossible_challenge', '🔥'),

  /// Carta de Punição Leve (pagando mico no domingo).
  punishment('punishment', '🤡'),

  /// Prêmio do fim de semana desbloqueado pelo cofre.
  rewardUnlocked('reward_unlocked', '🎉'),

  /// Aviso automático do app (virada de semana, meta batida...).
  system('system', '📣');

  const FeedPostType(this.id, this.emoji);

  final String id;
  final String emoji;

  static FeedPostType fromId(String? id) => FeedPostType.values.firstWhere(
        (type) => type.id == id,
        orElse: () => FeedPostType.system,
      );
}

/// Reações rápidas disponíveis no feed.
///
/// A chave é um slug ASCII (`fire`, `laugh`...) porque ela vira caminho de
/// campo no Firestore (`reactions.fire`) — emoji direto quebraria o FieldPath.
class Reactions {
  const Reactions._();

  static const Map<String, String> available = {
    'fire': '🔥',
    'muscle': '💪',
    'clap': '👏',
    'laugh': '😂',
    'heart': '❤️',
  };

  static String emojiFor(String key) => available[key] ?? '👍';
}

/// Publicação do feed privado dos 4 integrantes (`feed_posts`).
class FeedPost {
  const FeedPost({
    required this.id,
    required this.familyId,
    required this.authorId,
    required this.authorName,
    required this.type,
    this.authorAvatar = '🙂',
    this.authorPhotoUrl,
    this.message = '',
    this.photoUrl,
    this.photoData,
    this.photoExpiresAt,
    this.points = 0,
    this.durationMinutes = 0,
    this.activityLogId,
    this.reactions = const {},
    this.metadata = const {},
    this.createdAt,
  });

  final String id;
  final String familyId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String? authorPhotoUrl;

  final FeedPostType type;
  final String message;

  /// Foto do momento (comprovante da atividade ou do mico).
  /// Endereço da foto no Firebase Storage. Só existe em registro antigo:
  /// sem Storage no plano gratuito, a foto agora vai em [photoData].
  final String? photoUrl;

  /// A foto em base64, dentro do próprio documento (ver [PhotoProof]).
  /// Fica vazia depois de [photoExpiresAt] — a foto vale um dia.
  final String? photoData;

  /// Quando a foto deixa de ser exibida e pode ser apagada.
  final DateTime? photoExpiresAt;

  final int points;
  final int durationMinutes;
  final String? activityLogId;

  /// `{ 'fire': ['uid1','uid2'], 'laugh': ['uid3'] }`
  final Map<String, List<String>> reactions;

  /// Campos extras por tipo de carta (ex.: `toUserId` na Salva-Mãe/Pai).
  final Map<String, dynamic> metadata;

  final DateTime? createdAt;

  int reactionCount(String key) => reactions[key]?.length ?? 0;

  bool hasReacted(String key, String userId) =>
      reactions[key]?.contains(userId) ?? false;

  bool get isCard =>
      type == FeedPostType.saveCard ||
      type == FeedPostType.impossibleChallenge ||
      type == FeedPostType.punishment;

  factory FeedPost.fromMap(String id, Map<String, dynamic> map) {
    final rawReactions = FirestoreUtils.toMap(map['reactions']);
    return FeedPost(
      id: id,
      familyId: FirestoreUtils.toStringValue(map['familyId']),
      authorId: FirestoreUtils.toStringValue(map['authorId']),
      authorName: FirestoreUtils.toStringValue(map['authorName']),
      authorAvatar:
          FirestoreUtils.toStringValue(map['authorAvatar'], fallback: '🙂'),
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      type: FeedPostType.fromId(map['type'] as String?),
      message: FirestoreUtils.toStringValue(map['message']),
      photoUrl: map['photoUrl'] as String?,
      photoData: map['photoData'] as String?,
      photoExpiresAt: FirestoreUtils.toDateTime(map['photoExpiresAt']),
      points: FirestoreUtils.toInt(map['points']),
      durationMinutes: FirestoreUtils.toInt(map['durationMinutes']),
      activityLogId: map['activityLogId'] as String?,
      reactions: rawReactions.map(
        (key, value) => MapEntry(key, FirestoreUtils.toStringList(value)),
      ),
      metadata: FirestoreUtils.toMap(map['metadata']),
      createdAt: FirestoreUtils.toDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'authorPhotoUrl': authorPhotoUrl,
        'type': type.id,
        'message': message,
        'photoUrl': photoUrl,
        'photoData': photoData,
        'photoExpiresAt': photoExpiresAt,
        'points': points,
        'durationMinutes': durationMinutes,
        'activityLogId': activityLogId,
        'reactions': reactions,
        'metadata': metadata,
        'createdAt': createdAt,
      };
}
