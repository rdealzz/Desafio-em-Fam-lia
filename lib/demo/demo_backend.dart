import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/activity_log.dart';
import '../models/activity_type.dart';
import '../models/app_user.dart';
import '../models/family.dart';
import '../models/feed_post.dart';
import '../models/reward.dart';
import '../services/activity_service.dart';
import '../services/app_exception.dart';
import '../services/feed_service.dart';
import '../services/points_calculator.dart';
import '../state/session_controller.dart';
import 'demo_data.dart';

/// Backend de mentira, tudo em memória.
///
/// Guarda o mesmo comportamento do app real — registrar soma no cofre, reagir
/// liga e desliga, doar aplica o dobro — mas sem servidor nenhum. É o que a
/// página publicada usa para mostrar a interface funcionando.
///
/// Recarregar a página volta ao estado inicial. Nada é salvo em lugar algum.
class DemoBackend extends ChangeNotifier {
  DemoBackend()
      : _family = DemoData.familia,
        _members = [...DemoData.membros],
        _feed = [...DemoData.feed] {
    for (final member in _members) {
      _logs[member.id] = DemoData.logsDe(member.id);
    }
  }

  Family _family;
  List<AppUser> _members;
  List<FeedPost> _feed;
  final Map<String, List<ActivityLog>> _logs = {};

  final _feedController = StreamController<List<FeedPost>>.broadcast();
  final _logsController = StreamController<String>.broadcast();

  Family get family => _family;
  List<AppUser> get members => _members;
  AppUser get currentUser =>
      _members.firstWhere((m) => m.id == DemoData.eu.id);

  Stream<List<FeedPost>> watchFeed() async* {
    yield _feed;
    yield* _feedController.stream;
  }

  Stream<List<ActivityLog>> watchLogs(String userId) async* {
    yield _logs[userId] ?? const [];
    yield* _logsController.stream
        .where((id) => id == userId)
        .map((id) => _logs[id] ?? const <ActivityLog>[]);
  }

  void _emitFeed() {
    _feedController.add(_feed);
    notifyListeners();
  }

  void _replaceMember(AppUser updated) {
    _members = _members
        .map((m) => m.id == updated.id ? updated : m)
        .toList()
      ..sort((a, b) => b.pointsThisWeek.compareTo(a.pointsThisWeek));
  }

  /// Mesma sequência do app real: soma no cofre, libera prêmio, publica no
  /// mural. Só que tudo na memória do navegador.
  ActivityRegistrationResult registrar({
    required ActivityType type,
    required int durationMinutes,
    int steps = 0,
    Uint8List? photoBytes,
    String note = '',
  }) {
    final breakdown = PointsCalculator.calculate(
      type: type,
      minutes: durationMinutes,
      steps: steps,
    );
    if (breakdown.total <= 0) {
      throw AppException(
        'Tempo insuficiente: ${type.label} pontua a cada '
        '${type.blockMinutes} min.',
      );
    }

    final agora = DateTime.now();
    final eu = currentUser;
    final novoCofre = _family.vaultPoints + breakdown.total;

    final liberados = <Reward>[];
    final premios = _family.rewards.map((r) {
      if (!r.unlocked && novoCofre >= r.requiredPoints) {
        final aberto = r.copyWith(unlocked: true, unlockedAt: agora);
        liberados.add(aberto);
        return aberto;
      }
      return r;
    }).toList();

    _family = Family(
      id: _family.id,
      name: _family.name,
      inviteCode: _family.inviteCode,
      memberIds: _family.memberIds,
      weeklyGoal: _family.weeklyGoal,
      vaultPoints: novoCofre,
      requirePhotoProof: _family.requirePhotoProof,
      weekId: _family.weekId,
      weekStartAt: _family.weekStartAt,
      weekEndAt: _family.weekEndAt,
      rewards: premios,
    );

    final novaSequencia =
        eu.isActiveToday ? eu.currentStreak : eu.currentStreak + 1;

    _replaceMember(eu.copyWith(
      weeklyPoints: eu.pointsThisWeek + breakdown.total,
      totalPoints: eu.totalPoints + breakdown.total,
      currentStreak: novaSequencia,
      lastActivityAt: agora,
      statusMessage:
          '${type.label} de $durationMinutes min — +${breakdown.total} pts',
    ));

    _logs[eu.id] = [
      ActivityLog(
        id: 'demo_${agora.millisecondsSinceEpoch}',
        familyId: _family.id,
        userId: eu.id,
        userName: eu.displayName,
        type: type,
        durationMinutes: durationMinutes,
        steps: steps,
        points: breakdown.total,
        basePoints: breakdown.basePoints,
        stepsPoints: breakdown.stepsPoints,
        createdAt: agora,
        syncedAt: agora,
      ),
      ..._logs[eu.id] ?? const [],
    ];
    _logsController.add(eu.id);

    _feed = [
      FeedPost(
        id: 'demo_post_${agora.millisecondsSinceEpoch}',
        familyId: _family.id,
        authorId: eu.id,
        authorName: eu.displayName,
        authorAvatar: eu.avatarEmoji,
        type: FeedPostType.activity,
        message: note.isNotEmpty
            ? note
            : '${type.emoji} ${type.label} — $durationMinutes min',
        points: breakdown.total,
        durationMinutes: durationMinutes,
        metadata: {'activityType': type.id, 'steps': steps},
        createdAt: agora,
      ),
      for (final r in liberados)
        FeedPost(
          id: 'demo_reward_${r.id}_${agora.millisecondsSinceEpoch}',
          familyId: _family.id,
          authorId: 'system',
          authorName: _family.name,
          authorAvatar: '🎉',
          type: FeedPostType.rewardUnlocked,
          message: '${r.emoji} Prêmio liberado: ${r.title}!',
          createdAt: agora,
        ),
      ..._feed,
    ];
    _emitFeed();

    return ActivityRegistrationResult(
      pointsEarned: breakdown.total,
      vaultPoints: novoCofre,
      weeklyGoal: _family.weeklyGoal,
      currentStreak: novaSequencia,
      unlockedRewards: liberados,
    );
  }

  int doar({required String paraId, required int quantidade}) {
    final eu = currentUser;
    if (eu.saveCards <= 0) {
      throw const AppException('Você não tem cartas Salva-Mãe/Pai.');
    }
    final recebido = PointsCalculator.donationValue(quantidade);
    final destino = _members.firstWhere((m) => m.id == paraId);

    _replaceMember(eu.copyWith(
      weeklyPoints: eu.pointsThisWeek - quantidade,
      saveCards: eu.saveCards - 1,
    ));
    _replaceMember(destino.copyWith(
      weeklyPoints: destino.pointsThisWeek + recebido,
      totalPoints: destino.totalPoints + recebido,
      currentStreak: destino.currentStreak + 1,
      lastActivityAt: DateTime.now(),
      statusMessage: 'Sequência salva por ${eu.firstName}!',
    ));

    _family = Family(
      id: _family.id,
      name: _family.name,
      inviteCode: _family.inviteCode,
      memberIds: _family.memberIds,
      weeklyGoal: _family.weeklyGoal,
      vaultPoints: _family.vaultPoints + quantidade,
      requirePhotoProof: _family.requirePhotoProof,
      weekId: _family.weekId,
      weekStartAt: _family.weekStartAt,
      weekEndAt: _family.weekEndAt,
      rewards: _family.rewards,
    );

    publicar(FeedPost(
      id: 'demo_save_${DateTime.now().millisecondsSinceEpoch}',
      familyId: _family.id,
      authorId: eu.id,
      authorName: eu.displayName,
      authorAvatar: eu.avatarEmoji,
      type: FeedPostType.saveCard,
      message: '🦸 Carta Salva-Mãe/Pai! ${eu.firstName} doou $quantidade pts — '
          '${destino.firstName} recebeu $recebido pts.',
      points: recebido,
      createdAt: DateTime.now(),
    ));

    return recebido;
  }

  void publicar(FeedPost post) {
    _feed = [post, ..._feed];
    _emitFeed();
  }

  void reagir({
    required String postId,
    required String chave,
    required String userId,
    required bool ativa,
  }) {
    _feed = _feed.map((post) {
      if (post.id != postId) return post;
      final reacoes = {
        for (final e in post.reactions.entries) e.key: [...e.value],
      };
      final lista = reacoes.putIfAbsent(chave, () => []);
      if (ativa) {
        lista.remove(userId);
      } else if (!lista.contains(userId)) {
        lista.add(userId);
      }
      return FeedPost(
        id: post.id,
        familyId: post.familyId,
        authorId: post.authorId,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        authorPhotoUrl: post.authorPhotoUrl,
        type: post.type,
        message: post.message,
        photoUrl: post.photoUrl,
        points: post.points,
        durationMinutes: post.durationMinutes,
        activityLogId: post.activityLogId,
        reactions: reacoes,
        metadata: post.metadata,
        createdAt: post.createdAt,
      );
    }).toList();
    _emitFeed();
  }

  @override
  void dispose() {
    _feedController.close();
    _logsController.close();
    super.dispose();
  }
}

/// Sessão já pronta: a demonstração entra direto no dashboard, sem login.
class DemoSessionController extends ChangeNotifier
    implements SessionController {
  DemoSessionController(this._backend) {
    _backend.addListener(notifyListeners);
  }

  final DemoBackend _backend;

  @override
  SessionStatus get status => SessionStatus.ready;

  @override
  AppUser? get user => _backend.currentUser;

  @override
  Family? get family => _backend.family;

  @override
  List<AppUser> get members => _backend.members;

  @override
  bool get isReady => true;

  @override
  List<AppUser> get otherMembers =>
      _backend.members.where((m) => m.id != _backend.currentUser.id).toList();

  @override
  Future<void> signOut() async {
    // Não há de onde sair numa demonstração.
  }

  @override
  void dispose() {
    _backend.removeListener(notifyListeners);
    super.dispose();
  }
}

class DemoFeedService implements FeedService {
  DemoFeedService(this._backend);

  final DemoBackend _backend;

  @override
  Stream<List<FeedPost>> watchFeed(String familyId, {int limit = 50}) =>
      _backend.watchFeed();

  @override
  Stream<List<FeedPost>> watchActiveCards(String familyId) =>
      _backend.watchFeed().map((posts) => posts.where((p) => p.isCard).toList());

  @override
  Future<void> toggleReaction({
    required String postId,
    required String reactionKey,
    required String userId,
    required bool isActive,
  }) async {
    _backend.reagir(
      postId: postId,
      chave: reactionKey,
      userId: userId,
      ativa: isActive,
    );
  }

  @override
  Future<void> publishCard({
    required AppUser author,
    required FeedPostType type,
    required String message,
    Map<String, dynamic> metadata = const {},
  }) async {
    _backend.publicar(FeedPost(
      id: 'demo_card_${DateTime.now().millisecondsSinceEpoch}',
      familyId: author.familyId,
      authorId: author.id,
      authorName: author.displayName,
      authorAvatar: author.avatarEmoji,
      type: type,
      message: message,
      metadata: metadata,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> deletePost(String postId) async {}
}

class DemoActivityService implements ActivityService {
  DemoActivityService(this._backend);

  final DemoBackend _backend;

  @override
  Future<ActivityRegistrationResult> registerActivity({
    required AppUser user,
    required ActivityType type,
    required int durationMinutes,
    int steps = 0,
    Uint8List? photoBytes,
    String note = '',
    String source = 'manual',
    DateTime? performedAt,
    String? logId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _backend.registrar(
      type: type,
      durationMinutes: durationMinutes,
      steps: steps,
      photoBytes: photoBytes,
      note: note,
    );
  }

  @override
  Future<int> donatePoints({
    required AppUser donor,
    required String recipientId,
    required int amount,
    String message = '',
  }) async {
    return _backend.doar(paraId: recipientId, quantidade: amount);
  }

  @override
  Stream<List<ActivityLog>> watchUserLogs(String userId, {int limit = 60}) =>
      _backend.watchLogs(userId);

  @override
  Stream<List<ActivityLog>> watchRecentLogs(String familyId,
          {int limit = 30}) =>
      _backend.watchLogs(_backend.currentUser.id);
}
