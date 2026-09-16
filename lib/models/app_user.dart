import '../core/utils/firestore_utils.dart';
import '../core/utils/week_utils.dart';

/// Um integrante da família (coleção `users`, doc id = uid do Firebase Auth).
class AppUser {
  const AppUser({
    required this.id,
    required this.familyId,
    required this.displayName,
    this.username = '',
    this.email = '',
    this.role = 'membro',
    this.avatarEmoji = '🙂',
    this.avatarColor = 0,
    this.photoUrl,
    this.totalPoints = 0,
    this.weeklyPoints = 0,
    this.weekId = '',
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.saveCards = 1,
    this.lastActivityAt,
    this.statusMessage = '',
    this.createdAt,
  });

  final String id;
  final String familyId;
  final String displayName;

  /// Apelido de entrada, em forma canônica (minúsculo, sem acento).
  final String username;

  /// Guardado só se a pessoa quiser; a entrada é por apelido.
  final String email;

  /// Papel na família: `mae`, `pai`, `filho`, `nora`... usado só para exibição.
  final String role;

  /// Emoji herdado dos primeiros cadastros. Não aparece mais na interface
  /// (no navegador vira quadradinho); fica só para não perder dado antigo.
  final String avatarEmoji;

  /// Cor do perfil, em ARGB. Zero significa "ainda não escolheu" e o app usa
  /// uma cor derivada do id — assim ninguém começa igual a ninguém.
  final int avatarColor;

  /// Foto de perfil. Pode ser qualquer imagem: o cachorro, o gato, o que a
  /// pessoa quiser.
  final String? photoUrl;

  /// Pontos acumulados desde sempre (histórico, nunca zera).
  final int totalPoints;

  /// Pontos da semana corrente — a parcela deste membro dentro do cofre.
  final int weeklyPoints;

  /// Semana a que `weeklyPoints` se refere (ver [WeekUtils.weekId]).
  final String weekId;

  final int currentStreak;
  final int longestStreak;

  /// Cartas "Salva-Mãe/Pai" disponíveis para doar pontos.
  final int saveCards;

  final DateTime? lastActivityAt;

  /// Frase curta exibida no dashboard ("Já fez a caminhada!").
  final String statusMessage;

  final DateTime? createdAt;

  /// Pontos válidos para a semana atual (zera sozinho na virada da semana).
  int get pointsThisWeek =>
      weekId == WeekUtils.currentWeekId() ? weeklyPoints : 0;

  bool get isActiveToday {
    final last = lastActivityAt;
    if (last == null) return false;
    return WeekUtils.isSameDay(last, DateTime.now());
  }

  String get firstName => displayName.split(' ').first;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      familyId: FirestoreUtils.toStringValue(map['familyId']),
      displayName: FirestoreUtils.toStringValue(map['displayName'],
          fallback: 'Sem nome'),
      username: FirestoreUtils.toStringValue(map['username']),
      email: FirestoreUtils.toStringValue(map['email']),
      role: FirestoreUtils.toStringValue(map['role'], fallback: 'membro'),
      avatarEmoji:
          FirestoreUtils.toStringValue(map['avatarEmoji'], fallback: '🙂'),
      avatarColor: FirestoreUtils.toInt(map['avatarColor']),
      photoUrl: map['photoUrl'] as String?,
      totalPoints: FirestoreUtils.toInt(map['totalPoints']),
      weeklyPoints: FirestoreUtils.toInt(map['weeklyPoints']),
      weekId: FirestoreUtils.toStringValue(map['weekId']),
      currentStreak: FirestoreUtils.toInt(map['currentStreak']),
      longestStreak: FirestoreUtils.toInt(map['longestStreak']),
      saveCards: FirestoreUtils.toInt(map['saveCards'], fallback: 1),
      lastActivityAt: FirestoreUtils.toDateTime(map['lastActivityAt']),
      statusMessage: FirestoreUtils.toStringValue(map['statusMessage']),
      createdAt: FirestoreUtils.toDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'displayName': displayName,
        'username': username,
        'email': email,
        'role': role,
        'avatarEmoji': avatarEmoji,
        'avatarColor': avatarColor,
        'photoUrl': photoUrl,
        'totalPoints': totalPoints,
        'weeklyPoints': weeklyPoints,
        'weekId': weekId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'saveCards': saveCards,
        'lastActivityAt': lastActivityAt,
        'statusMessage': statusMessage,
        'createdAt': createdAt,
      };

  AppUser copyWith({
    String? familyId,
    String? displayName,
    String? role,
    String? avatarEmoji,
    int? avatarColor,
    String? photoUrl,
    int? totalPoints,
    int? weeklyPoints,
    String? weekId,
    int? currentStreak,
    int? longestStreak,
    int? saveCards,
    DateTime? lastActivityAt,
    String? statusMessage,
  }) {
    return AppUser(
      id: id,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
      username: username,
      email: email,
      role: role ?? this.role,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarColor: avatarColor ?? this.avatarColor,
      photoUrl: photoUrl ?? this.photoUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      weekId: weekId ?? this.weekId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      saveCards: saveCards ?? this.saveCards,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      statusMessage: statusMessage ?? this.statusMessage,
      createdAt: createdAt,
    );
  }
}
