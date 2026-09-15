import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_utils.dart';
import '../core/utils/week_utils.dart';
import '../models/activity_log.dart';
import '../models/activity_type.dart';
import '../models/app_user.dart';
import '../models/family.dart';
import '../models/feed_post.dart';
import '../models/reward.dart';
import 'app_exception.dart';
import 'firestore_refs.dart';
import 'points_calculator.dart';
import 'storage_service.dart';

/// O que aconteceu depois de registrar uma atividade — a tela usa para o
/// feedback ("+150 pts", "prêmio desbloqueado!").
class ActivityRegistrationResult {
  const ActivityRegistrationResult({
    required this.pointsEarned,
    required this.vaultPoints,
    required this.weeklyGoal,
    required this.currentStreak,
    required this.unlockedRewards,
  });

  final int pointsEarned;
  final int vaultPoints;
  final int weeklyGoal;
  final int currentStreak;
  final List<Reward> unlockedRewards;

  bool get goalReached => vaultPoints >= weeklyGoal;
}

/// Regras de escrita do app: registrar atividade e aplicar a Carta
/// "Salva-Mãe/Pai".
///
/// Tudo que mexe no cofre passa por `runTransaction`: quatro pessoas
/// registrando atividade ao mesmo tempo não podem sobrescrever o total uma
/// da outra. A transação lê família + usuário, recalcula e grava de uma vez;
/// se alguém escreveu no meio, o Firestore repete a operação sozinho.
class ActivityService {
  ActivityService(this._refs, this._storage);

  final FirestoreRefs _refs;
  final StorageService _storage;

  /// Registra uma atividade e deposita os pontos no cofre da família.
  ///
  /// A foto vai para o Storage ANTES da transação — upload é lento e não pode
  /// rodar dentro de um bloco que o Firestore pode reexecutar.
  Future<ActivityRegistrationResult> registerActivity({
    required AppUser user,
    required ActivityType type,
    required int durationMinutes,
    int steps = 0,
    File? photo,
    String note = '',
    String source = 'manual',
    DateTime? performedAt,
    String? logId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (user.familyId.isEmpty) {
      throw const AppException('Você ainda não faz parte de uma família.');
    }

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

    String? photoUrl;
    if (photo != null) {
      photoUrl = await _storage
          .uploadActivityProof(
            familyId: user.familyId,
            userId: user.id,
            file: photo,
          )
          // Sem rede o upload fica pendurado tentando de novo. O prazo devolve
          // o controle para quem chamou, que decide entre avisar ou enfileirar.
          .timeout(timeout);
    }

    // Quando a atividade ACONTECEU. Difere de agora num registro que passou
    // pela fila offline — e é essa hora que vale para o dia, a sequência e o
    // histórico.
    final at = performedAt ?? DateTime.now();
    final now = DateTime.now();

    // Semana do cofre é sempre a de agora: um registro atrasado não pode
    // ressuscitar o cofre de uma semana encerrada nem zerar o da semana atual.
    final weekId = WeekUtils.weekId(now);

    // Semana do registro é a de quando foi feito — o histórico guarda a verdade.
    final logWeekId = WeekUtils.weekId(at);

    // Id determinístico quando vem da fila: se o app morrer entre gravar e
    // limpar a fila, a repetição cai na guarda de idempotência abaixo em vez
    // de creditar os pontos duas vezes.
    final logRef = logId != null
        ? _refs.activityLogs.doc(logId)
        : _refs.activityLogs.doc();
    final feedRef = _refs.feedPosts.doc();
    final familyRef = _refs.family(user.familyId);
    final userRef = _refs.user(user.id);

    try {
      return await _refs.db.runTransaction<ActivityRegistrationResult>(
      timeout: timeout,
      (tx) async {
      // --- 1. Leituras (todas antes de qualquer escrita) -------------------
      final existingLog = await tx.get(logRef);
      final familySnap = await tx.get(familyRef);
      final userSnap = await tx.get(userRef);

      if (!familySnap.exists) {
        throw const AppException('Família não encontrada.');
      }
      if (!userSnap.exists) {
        throw const AppException('Perfil não encontrado.');
      }

      // Já aplicado numa tentativa anterior: sai sem escrever nada. É o que
      // impede crédito em dobro quando o app morre entre gravar e limpar a
      // fila offline. Fica depois das checagens acima porque lê os dois docs.
      if (existingLog.exists) {
        final family = Family.fromMap(familySnap.id, familySnap.data()!);
        return ActivityRegistrationResult(
          pointsEarned: FirestoreUtils.toInt(existingLog.data()?['points']),
          vaultPoints: family.vaultPoints,
          weeklyGoal: family.weeklyGoal,
          currentStreak:
              FirestoreUtils.toInt(userSnap.data()?['currentStreak']),
          unlockedRewards: const [],
        );
      }

      final family = Family.fromMap(familySnap.id, familySnap.data()!);
      final currentUser = AppUser.fromMap(userSnap.id, userSnap.data()!);

      // Conferido aqui dentro, contra o documento da família, e não só na
      // interface: a tela pode estar com uma cópia velha da configuração.
      if (family.requirePhotoProof && (photoUrl == null || photoUrl.isEmpty)) {
        throw const AppException(
          'Esta família exige foto comprovante. Anexe a foto do momento.',
        );
      }

      // --- 2. Virada de semana ---------------------------------------------
      // Se o cofre ainda aponta para a semana passada, ele zera aqui — antes
      // de somar. Assim ninguém precisa de um job agendado no backend.
      final isNewWeek = family.weekId != weekId;
      final vaultBase = isNewWeek ? 0 : family.vaultPoints;
      final rewardsBase = isNewWeek
          ? family.rewards
              .map((r) => Reward(
                    id: r.id,
                    title: r.title,
                    description: r.description,
                    emoji: r.emoji,
                    requiredPoints: r.requiredPoints,
                    level: r.level,
                  ))
              .toList()
          : family.rewards;

      final userWeeklyBase =
          currentUser.weekId == weekId ? currentUser.weeklyPoints : 0;

      // --- 3. Novos totais --------------------------------------------------
      final newVault = vaultBase + breakdown.total;
      final newStreak = _nextStreak(currentUser, at);
      final newLongest = newStreak > currentUser.longestStreak
          ? newStreak
          : currentUser.longestStreak;

      final unlocked = <Reward>[];
      final updatedRewards = rewardsBase.map((reward) {
        if (!reward.unlocked && newVault >= reward.requiredPoints) {
          final opened = reward.copyWith(unlocked: true, unlockedAt: now);
          unlocked.add(opened);
          return opened;
        }
        return reward;
      }).toList();

      // --- 4. Escritas ------------------------------------------------------
      final log = ActivityLog(
        id: logRef.id,
        familyId: user.familyId,
        userId: user.id,
        userName: currentUser.displayName,
        type: type,
        durationMinutes: durationMinutes,
        steps: type.tracksSteps ? steps : 0,
        points: breakdown.total,
        basePoints: breakdown.basePoints,
        stepsPoints: breakdown.stepsPoints,
        photoUrl: photoUrl,
        note: note,
        weekId: logWeekId,
        source: source,
      );

      tx.set(logRef, {
        ...log.toMap(),
        // Hora em que a atividade foi feita, não em que sincronizou.
        'createdAt': Timestamp.fromDate(at),
        'syncedAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'totalPoints': currentUser.totalPoints + breakdown.total,
        'weeklyPoints': userWeeklyBase + breakdown.total,
        'weekId': weekId,
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastActivityAt': Timestamp.fromDate(at),
        'statusMessage':
            '${type.label} de $durationMinutes min — +${breakdown.total} pts',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(familyRef, {
        'vaultPoints': newVault,
        'weekId': weekId,
        'weekStartAt': Timestamp.fromDate(WeekUtils.startOfWeek(now)),
        'weekEndAt': Timestamp.fromDate(WeekUtils.endOfWeek(now)),
        'rewards': updatedRewards.map((r) => r.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(feedRef, {
        ...FeedPost(
          id: feedRef.id,
          familyId: user.familyId,
          authorId: user.id,
          authorName: currentUser.displayName,
          authorAvatar: currentUser.avatarEmoji,
          authorPhotoUrl: currentUser.photoUrl,
          type: FeedPostType.activity,
          message: note.isNotEmpty
              ? note
              : '${type.emoji} ${type.label} — $durationMinutes min',
          photoUrl: photoUrl,
          points: breakdown.total,
          durationMinutes: durationMinutes,
          activityLogId: logRef.id,
          metadata: {
            'activityType': type.id,
            'steps': type.tracksSteps ? steps : 0,
            'streak': newStreak,
            // Quando o exercício foi feito, além de quando o post apareceu.
            'performedAt': Timestamp.fromDate(at),
            // Registro que passou pela fila offline aparece marcado: a família
            // vê que chegou atrasado em vez de achar que acabou de acontecer.
            'offlineSync': source == 'offline_queue',
          },
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cada prêmio liberado vira um aviso próprio no mural.
      for (final reward in unlocked) {
        final rewardRef = _refs.feedPosts.doc();
        tx.set(rewardRef, {
          ...FeedPost(
            id: rewardRef.id,
            familyId: user.familyId,
            authorId: 'system',
            authorName: family.name,
            authorAvatar: '🎉',
            type: FeedPostType.rewardUnlocked,
            message: '${reward.emoji} Prêmio liberado: ${reward.title}! '
                'O cofre chegou a ${reward.requiredPoints} pontos.',
            metadata: {'rewardId': reward.id},
          ).toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return ActivityRegistrationResult(
        pointsEarned: breakdown.total,
        vaultPoints: newVault,
        weeklyGoal: family.weeklyGoal,
        currentStreak: newStreak,
        unlockedRewards: unlocked,
      );
    },
      );
    } on FirebaseException catch (e) {
      throw _traduzirRecusa(e);
    }
  }

  /// O servidor recusa por regra, não por capricho — e a mensagem precisa
  /// dizer o que arrumar. As duas causas reais são foto faltando e relógio
  /// fora da janela aceita.
  AppException _traduzirRecusa(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return const AppException(
        'O servidor recusou o registro. Verifique se a foto foi anexada e se '
        'a data e hora do celular estão corretas (deixe no ajuste automático).',
      );
    }
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
      return const AppException('Sem conexão com o servidor.');
    }
    return AppException(e.message ?? 'Não foi possível registrar agora.');
  }

  /// Carta "Salva-Mãe / Salva-Pai".
  ///
  /// O doador abre mão de [amount] pontos e quem recebe ganha o DOBRO —
  /// o esforço extra de quem treinou por dois vale mais que a simples
  /// transferência. Efeito no cofre: `+amount` (saem `amount`, entram `2x`).
  /// A sequência diária de quem recebe também é salva.
  Future<int> donatePoints({
    required AppUser donor,
    required String recipientId,
    required int amount,
    String message = '',
  }) async {
    if (amount <= 0) {
      throw const AppException('Informe quantos pontos quer doar.');
    }
    if (donor.id == recipientId) {
      throw const AppException('A carta só vale para outro integrante.');
    }

    final now = DateTime.now();
    final weekId = WeekUtils.weekId(now);
    final donorRef = _refs.user(donor.id);
    final recipientRef = _refs.user(recipientId);
    final familyRef = _refs.family(donor.familyId);
    final feedRef = _refs.feedPosts.doc();

    return _refs.db.runTransaction<int>((tx) async {
      final donorSnap = await tx.get(donorRef);
      final recipientSnap = await tx.get(recipientRef);
      final familySnap = await tx.get(familyRef);

      if (!donorSnap.exists || !recipientSnap.exists || !familySnap.exists) {
        throw const AppException('Não foi possível carregar os perfis.');
      }

      final donorUser = AppUser.fromMap(donorSnap.id, donorSnap.data()!);
      final recipient = AppUser.fromMap(recipientSnap.id, recipientSnap.data()!);
      final family = Family.fromMap(familySnap.id, familySnap.data()!);

      if (recipient.familyId != donorUser.familyId) {
        throw const AppException('Esse integrante é de outra família.');
      }
      if (donorUser.saveCards <= 0) {
        throw const AppException(
          'Você não tem cartas Salva-Mãe/Pai disponíveis.',
        );
      }

      final donorWeekly =
          donorUser.weekId == weekId ? donorUser.weeklyPoints : 0;
      if (donorWeekly < amount) {
        throw AppException(
          'Você tem $donorWeekly pts nesta semana — não dá para doar $amount.',
        );
      }

      final received = PointsCalculator.donationValue(amount);
      final recipientWeekly =
          recipient.weekId == weekId ? recipient.weeklyPoints : 0;

      // O cofre já contava com os `amount` do doador; o ganho líquido da
      // carta é a diferença até o dobro.
      final isNewWeek = family.weekId != weekId;
      final vaultBase = isNewWeek ? 0 : family.vaultPoints;
      final newVault = vaultBase + (received - amount);

      final recipientStreak = _nextStreak(recipient, now);

      tx.update(donorRef, {
        'weeklyPoints': donorWeekly - amount,
        'weekId': weekId,
        'saveCards': donorUser.saveCards - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(recipientRef, {
        'weeklyPoints': recipientWeekly + received,
        'totalPoints': recipient.totalPoints + received,
        'weekId': weekId,
        'currentStreak': recipientStreak,
        'longestStreak': recipientStreak > recipient.longestStreak
            ? recipientStreak
            : recipient.longestStreak,
        'lastActivityAt': Timestamp.fromDate(at),
        'statusMessage': 'Sequência salva por ${donorUser.firstName}!',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(familyRef, {
        'vaultPoints': newVault,
        'weekId': weekId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(feedRef, {
        ...FeedPost(
          id: feedRef.id,
          familyId: donorUser.familyId,
          authorId: donorUser.id,
          authorName: donorUser.displayName,
          authorAvatar: donorUser.avatarEmoji,
          authorPhotoUrl: donorUser.photoUrl,
          type: FeedPostType.saveCard,
          message: message.isNotEmpty
              ? message
              : '🦸 Carta Salva-Mãe/Pai! ${donorUser.firstName} treinou em '
                  'dobro e doou $amount pts — ${recipient.firstName} recebeu '
                  '$received pts e manteve a sequência.',
          points: received,
          metadata: {
            'toUserId': recipient.id,
            'toUserName': recipient.displayName,
            'donatedPoints': amount,
            'receivedPoints': received,
          },
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return received;
    });
  }

  /// Regra da sequência diária: manteve ontem = +1; já registrou hoje = mantém;
  /// furou um dia = recomeça em 1.
  int _nextStreak(AppUser user, DateTime now) {
    final last = user.lastActivityAt;
    if (last == null) return 1;
    if (WeekUtils.isSameDay(last, now)) {
      return user.currentStreak > 0 ? user.currentStreak : 1;
    }
    if (WeekUtils.isYesterday(last, now)) return user.currentStreak + 1;
    return 1;
  }

  /// Histórico de um integrante — alimenta a tela "Meu Progresso".
  ///
  /// 60 registros cobrem com folga as últimas semanas; o strip de 7 dias e as
  /// estatísticas são calculados em cima desta mesma lista, sem consulta extra.
  Stream<List<ActivityLog>> watchUserLogs(String userId, {int limit = 60}) {
    return _refs.activityLogs
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ActivityLog.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Últimos registros da família (histórico da Tela 1).
  Stream<List<ActivityLog>> watchRecentLogs(String familyId, {int limit = 30}) {
    return _refs.activityLogs
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ActivityLog.fromMap(doc.id, doc.data()))
            .toList());
  }
}
