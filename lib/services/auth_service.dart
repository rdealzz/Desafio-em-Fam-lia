import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'app_exception.dart';
import 'family_service.dart';
import 'firestore_refs.dart';

/// Autenticação por e-mail/senha + criação do perfil e do grupo familiar.
class AuthService {
  AuthService(this._auth, this._refs, this._familyService);

  final FirebaseAuth _auth;
  final FirestoreRefs _refs;
  final FamilyService _familyService;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageFor(e));
    }
  }

  /// Cria a conta e, na sequência, o perfil no Firestore.
  ///
  /// Quem cria a família vira o primeiro integrante; os outros três entram
  /// com o código do convite.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required String avatarEmoji,
    String? familyName,
    String? inviteCode,
  }) async {
    if ((familyName == null || familyName.trim().isEmpty) &&
        (inviteCode == null || inviteCode.trim().isEmpty)) {
      throw const AppException(
        'Crie uma família nova ou informe o código de convite.',
      );
    }

    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageFor(e));
    }

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(name.trim());

    // Perfil sem família ainda — o passo seguinte define qual.
    var user = AppUser(
      id: uid,
      familyId: '',
      displayName: name.trim(),
      email: email.trim(),
      role: role,
      avatarEmoji: avatarEmoji,
    );

    await _refs.user(uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (inviteCode != null && inviteCode.trim().isNotEmpty) {
      final family = await _familyService.joinFamilyByCode(
        inviteCode: inviteCode,
        userId: uid,
      );
      user = user.copyWith(familyId: family.id);
    } else {
      // createFamily já grava o familyId no perfil do dono.
      final family = await _familyService.createFamily(
        name: familyName!.trim(),
        ownerId: uid,
      );
      user = user.copyWith(familyId: family.id);
    }

    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_messageFor(e));
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Esse e-mail já tem conta. Faça login.';
      case 'weak-password':
        return 'A senha precisa de pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão. Tente de novo.';
      default:
        return e.message ?? 'Não foi possível concluir. Tente de novo.';
    }
  }
}
