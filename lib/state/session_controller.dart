import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/family.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';

enum SessionStatus {
  /// Ainda verificando se existe sessão salva.
  loading,

  /// Sem ninguém logado — mostra a tela de entrada.
  signedOut,

  /// Logado, mas o perfil ainda não está ligado a uma família.
  needsFamily,

  /// Tudo carregado: usuário + família.
  ready,
}

/// Estado global da sessão: quem está logado, sua família e os 4 integrantes.
///
/// Mantém três assinaturas do Firestore vivas (usuário, família, integrantes)
/// para que qualquer tela reflita o cofre em tempo real.
class SessionController extends ChangeNotifier {
  SessionController({
    required AuthService authService,
    required FamilyService familyService,
  })  : _authService = authService,
        _familyService = familyService {
    _authSubscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _authService;
  final FamilyService _familyService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<Family?>? _familySubscription;
  StreamSubscription<List<AppUser>>? _membersSubscription;

  SessionStatus _status = SessionStatus.loading;

  /// Qual família já está sendo observada. Sem isso, cada atualização do
  /// perfil que chegasse antes do primeiro snapshot da família abriria uma
  /// assinatura nova (listeners duplicados e leituras repetidas).
  String? _watchedFamilyId;

  AppUser? _user;
  Family? _family;
  List<AppUser> _members = const [];

  SessionStatus get status => _status;
  AppUser? get user => _user;
  Family? get family => _family;
  List<AppUser> get members => _members;

  bool get isReady => _status == SessionStatus.ready;

  /// Os outros integrantes — usado na Carta Salva-Mãe/Pai.
  List<AppUser> get otherMembers =>
      _members.where((member) => member.id != _user?.id).toList();

  void _onAuthChanged(User? firebaseUser) {
    _cancelDataSubscriptions();

    if (firebaseUser == null) {
      _user = null;
      _family = null;
      _members = const [];
      _setStatus(SessionStatus.signedOut);
      return;
    }

    _setStatus(SessionStatus.loading);
    _userSubscription =
        _familyService.watchUser(firebaseUser.uid).listen(_onUserChanged);
  }

  void _onUserChanged(AppUser? user) {
    _user = user;

    if (user == null) {
      // Documento ainda sendo criado logo após o cadastro.
      _setStatus(SessionStatus.loading);
      return;
    }

    if (user.familyId.isEmpty) {
      _familySubscription?.cancel();
      _membersSubscription?.cancel();
      _watchedFamilyId = null;
      _family = null;
      _members = const [];
      _setStatus(SessionStatus.needsFamily);
      return;
    }

    // Reassina só quando a família muda (entrou/trocou de grupo).
    if (_watchedFamilyId != user.familyId) {
      _watchedFamilyId = user.familyId;
      _familySubscription?.cancel();
      _membersSubscription?.cancel();

      _familySubscription =
          _familyService.watchFamily(user.familyId).listen((family) {
        _family = family;
        _setStatus(
          family == null ? SessionStatus.needsFamily : SessionStatus.ready,
        );
      });

      _membersSubscription =
          _familyService.watchMembers(user.familyId).listen((members) {
        _members = members;
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void _setStatus(SessionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _cancelDataSubscriptions() {
    _watchedFamilyId = null;
    _userSubscription?.cancel();
    _familySubscription?.cancel();
    _membersSubscription?.cancel();
    _userSubscription = null;
    _familySubscription = null;
    _membersSubscription = null;
  }

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
