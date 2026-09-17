import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/week_utils.dart';
import '../models/app_user.dart';
import '../models/family.dart';
import '../models/reward.dart';
import 'app_exception.dart';
import 'firestore_refs.dart';

/// Criação e leitura do grupo familiar.
class FamilyService {
  FamilyService(this._refs);

  final FirestoreRefs _refs;

  static const int defaultWeeklyGoal = 5000;
  static const int maxMembers = 4;

  /// Nome já preenchido na hora de criar a família. Continua editável — é um
  /// campo de texto comum, só vem escrito.
  static const String nomePadrao = 'Tisulje';

  Stream<Family?> watchFamily(String familyId) {
    return _refs.family(familyId).snapshots().map(
          (snap) => snap.exists ? Family.fromMap(snap.id, snap.data()!) : null,
        );
  }

  /// Os integrantes da família, já ordenados por pontos da semana (maior
  /// primeiro) — o último da lista é quem paga o mico de domingo.
  Stream<List<AppUser>> watchMembers(String familyId) {
    return _refs.users
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snap) {
      final members = snap.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.pointsThisWeek.compareTo(a.pointsThisWeek));
      return members;
    });
  }

  Stream<AppUser?> watchUser(String uid) {
    return _refs.user(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null,
        );
  }

  /// Cria a família com o cofre zerado na semana corrente e os prêmios padrão.
  /// [requirePhotoProof] volta a nascer ligado: a foto deixou de depender do
  /// Firebase Storage — vai dentro do documento, em base64, e some em um dia
  /// (ver [PhotoProof]). A prova é o que tira a discussão sobre quem fez o
  /// quê, então o padrão é exigi-la; quem não quiser desliga em Ajustes.
  Future<Family> createFamily({
    required String name,
    required String ownerId,
    int weeklyGoal = defaultWeeklyGoal,
    bool requirePhotoProof = true,
  }) async {
    final now = DateTime.now();
    final ref = _refs.families.doc();
    final family = Family(
      id: ref.id,
      name: name,
      inviteCode: _generateInviteCode(),
      memberIds: [ownerId],
      weeklyGoal: weeklyGoal,
      weekId: WeekUtils.weekId(now),
      weekStartAt: WeekUtils.startOfWeek(now),
      weekEndAt: WeekUtils.endOfWeek(now),
      rewards: Reward.defaults(weeklyGoal),
      requirePhotoProof: requirePhotoProof,
    );

    // Criar a família e ligar o dono a ela precisa acontecer junto: se só a
    // família fosse criada, o perfil ficaria órfão e o app travaria na tela
    // "entre numa família".
    final batch = _refs.db.batch();
    batch.set(ref, {
      ...family.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_refs.user(ownerId), {'familyId': ref.id});
    await batch.commit();

    return family;
  }

  /// Entra numa família pelo código do convite (máx. 4 integrantes).
  Future<Family> joinFamilyByCode({
    required String inviteCode,
    required String userId,
  }) async {
    final query = await _refs.families
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw const AppException('Código de convite não encontrado.');
    }

    final doc = query.docs.first;
    final family = Family.fromMap(doc.id, doc.data());

    if (family.memberIds.length >= maxMembers &&
        !family.memberIds.contains(userId)) {
      throw const AppException('Esta família já tem 4 integrantes.');
    }

    // Idempotente: quem já é membro apenas tem o perfil reapontado — cobre o
    // caso de um cadastro interrompido no meio.
    final batch = _refs.db.batch();
    batch.update(doc.reference, {
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    batch.update(_refs.user(userId), {'familyId': family.id});
    await batch.commit();

    return family;
  }

  Future<void> updateWeeklyGoal(String familyId, int goal) {
    return _refs.family(familyId).update({
      'weeklyGoal': goal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Liga/desliga a exigência de foto comprovante.
  Future<void> setRequirePhotoProof(String familyId, bool required) {
    return _refs.family(familyId).update({
      'requirePhotoProof': required,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRewards(String familyId, List<Reward> rewards) {
    return _refs.family(familyId).update({
      'rewards': rewards.map((r) => r.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
