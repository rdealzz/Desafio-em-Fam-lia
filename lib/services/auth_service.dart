import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'app_exception.dart';
import 'family_service.dart';
import 'firestore_refs.dart';

/// Entrada no app com **usuário e senha** — sem e-mail.
///
/// Pedir e-mail para a família inteira é atrito: nem todo mundo lembra qual
/// usa, e ninguém quer digitar endereço em teclado de celular. Aqui cada um
/// escolhe um apelido curto.
///
/// Por baixo continua sendo o Firebase Authentication, que só trabalha com
/// e-mail: o apelido vira `apelido@desafioemfamilia.app` internamente. Esse
/// endereço nunca é mostrado nem recebe mensagem — serve de identificador, e
/// de quebra o próprio Firebase garante que dois apelidos não se repitam.
///
/// **Limitação, dita de frente:** sem e-mail de verdade não existe
/// recuperação automática de senha. Quem esquecer precisa criar outra conta.
/// Para uma família de quatro é um custo pequeno perto de simplificar a
/// entrada — e dá para acrescentar recuperação depois, se incomodar.
class AuthService {
  AuthService(this._auth, this._refs, this._familyService);

  final FirebaseAuth _auth;
  final FirestoreRefs _refs;
  final FamilyService _familyService;

  /// Domínio interno. Nunca aparece na interface.
  static const String _dominio = 'desafioemfamilia.app';

  static const int minUsername = 3;
  static const int maxUsername = 20;

  /// Senha curta é permitida de propósito: "123" serve. A ideia é a família
  /// entrar sem atrito, não proteger segredo de estado.
  static const int minSenha = 3;

  /// O Firebase recusa senha com menos de 6 caracteres, e não há como
  /// desligar isso no servidor. Então a senha que a pessoa digita vai
  /// acrescida deste sufixo fixo antes de sair do aparelho — ela digita
  /// "123", o Firebase recebe algo longo o bastante para aceitar.
  ///
  /// O sufixo é constante e está no código, então ele NÃO acrescenta
  /// segurança: uma senha de três dígitos continua sendo uma senha de três
  /// dígitos. É a troca consciente por facilidade num app de quatro pessoas.
  /// O Firebase ainda limita tentativas seguidas, o que cobre o básico.
  static const String _sufixoSenha = '.desafio-em-familia';

  static String _senhaReal(String digitada) => '$digitada$_sufixoSenha';

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Deixa o apelido em forma canônica: minúsculas, sem acento, sem espaço.
  ///
  /// "José Maria" e "jose.maria" chegam ao mesmo lugar — quem digita não
  /// precisa lembrar como escreveu no cadastro.
  static String normalizarUsuario(String bruto) {
    var s = bruto.trim().toLowerCase();
    const acentos = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'ê': 'e', 'è': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
    };
    acentos.forEach((de, para) => s = s.replaceAll(de, para));
    s = s.replaceAll(RegExp(r'\s+'), '.');
    return s.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }

  /// Mensagem do que está errado no apelido, ou `null` se estiver bom.
  static String? validarUsuario(String bruto) {
    final u = normalizarUsuario(bruto);
    if (u.length < minUsername) {
      return 'O usuário precisa de pelo menos $minUsername letras.';
    }
    if (u.length > maxUsername) {
      return 'O usuário pode ter no máximo $maxUsername caracteres.';
    }
    if (!RegExp(r'^[a-z]').hasMatch(u)) {
      return 'O usuário precisa começar com uma letra.';
    }
    return null;
  }

  static String _emailDe(String usuario) =>
      '${normalizarUsuario(usuario)}@$_dominio';

  /// Os e-mails com que vale a pena tentar entrar, na ordem.
  ///
  /// O primeiro é o apelido@domínio de sempre, que atende todo mundo que nunca
  /// cadastrou e-mail de recuperação — é o caminho de 99% dos logins, e por
  /// isso vem antes de qualquer leitura no Firestore.
  Future<List<String>> _emailsPossiveis(String usuario) async {
    final padrao = _emailDe(usuario);
    try {
      final mapa = await _refs.username(normalizarUsuario(usuario)).get();
      final dados = mapa.data();
      if (dados == null) return [padrao];
      // `pendingEmail` entra na lista porque o Firebase só troca o e-mail da
      // conta quando a pessoa clica no link de confirmação — e nós não ficamos
      // sabendo da hora. Sem ele, o primeiro login depois da confirmação
      // falharia e trancaria a pessoa para fora.
      return {
        padrao,
        if (dados['authEmail'] is String) dados['authEmail'] as String,
        if (dados['pendingEmail'] is String) dados['pendingEmail'] as String,
      }.where((e) => e.isNotEmpty).toList();
    } catch (_) {
      // Mapa indisponível não pode impedir o login normal.
      return [padrao];
    }
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final erro = validarUsuario(username);
    if (erro != null) throw AppException(erro);

    FirebaseAuthException? ultimo;

    // Duas senhas por e-mail: a do app (com o sufixo) e a crua.
    //
    // A crua existe por causa da recuperação: quem redefine pelo link do
    // e-mail digita a senha na página do Firebase, que não conhece o sufixo.
    // Sem esta segunda tentativa, a pessoa redefiniria a senha e continuaria
    // sem conseguir entrar — recuperação que não recupera.
    for (final email in await _emailsPossiveis(username)) {
      for (final senha in [_senhaReal(password), password]) {
        try {
          final credencial = await _auth.signInWithEmailAndPassword(
            email: email,
            password: senha,
          );
          // Senha crua significa que veio da página de redefinição: devolve a
          // conta à convenção do app, para a pessoa seguir digitando o mesmo.
          if (senha == password) {
            try {
              await credencial.user?.updatePassword(_senhaReal(password));
            } catch (_) {
              // Se não der, o login desta vez já funcionou e a próxima
              // tentativa cai de novo no caminho da senha crua.
            }
          }
          await _anotarMapa(usuario: username, conta: credencial.user);
          return;
        } on FirebaseAuthException catch (e) {
          ultimo = e;
          // Só vale insistir enquanto o erro for de credencial. Conta
          // desativada, rede fora ou excesso de tentativas não melhoram com
          // mais tentativas — e mais tentativas pioram o excesso.
          const insistir = {
            'user-not-found',
            'wrong-password',
            'invalid-credential',
            'invalid-login-credentials',
          };
          if (!insistir.contains(e.code)) {
            throw AppException(_mensagem(e));
          }
        }
      }
    }
    throw AppException(_mensagem(
      ultimo ?? FirebaseAuthException(code: 'invalid-credential'),
    ));
  }

  /// Mantém `usernames/{apelido}` apontando para o e-mail atual da conta.
  ///
  /// Roda depois de cada login bem-sucedido em vez de só no cadastro: assim a
  /// conta criada antes deste mapa existir ganha o dela na primeira entrada, e
  /// uma troca de e-mail confirmada se acerta sozinha.
  Future<void> _anotarMapa({
    required String usuario,
    required User? conta,
    String? pendingEmail,
  }) async {
    final email = conta?.email;
    if (conta == null || email == null) return;
    try {
      await _refs.username(normalizarUsuario(usuario)).set({
        'uid': conta.uid,
        'authEmail': email,
        if (pendingEmail != null) 'pendingEmail': pendingEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // O mapa é conveniência; sem ele o login padrão continua funcionando.
    }
  }

  /// O e-mail de recuperação já valendo, ou `null` se a pessoa não cadastrou.
  ///
  /// O apelido@domínio interno não conta: ele não recebe mensagem nenhuma.
  String? get emailDeRecuperacao {
    final email = _auth.currentUser?.email;
    if (email == null || email.endsWith('@$_dominio')) return null;
    return email;
  }

  /// Começa o cadastro do e-mail de recuperação.
  ///
  /// O Firebase manda uma mensagem de confirmação e só troca o e-mail da conta
  /// quando a pessoa clica no link. Até lá nada muda — inclusive o login, que
  /// continua pelo apelido.
  Future<void> cadastrarEmailDeRecuperacao(String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('Você precisa estar conectado.');
    }
    final limpo = email.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(limpo)) {
      throw const AppException('Esse e-mail não parece válido.');
    }
    if (limpo.toLowerCase().endsWith('@$_dominio')) {
      throw const AppException('Use um e-mail de verdade, que você abre.');
    }
    try {
      await user.verifyBeforeUpdateEmail(limpo);
      final doc = await _refs.user(user.uid).get();
      final apelido = doc.data()?['username'] as String? ?? '';
      if (apelido.isNotEmpty) {
        await _anotarMapa(usuario: apelido, conta: user, pendingEmail: limpo);
      }
    } on FirebaseAuthException catch (e) {
      throw AppException(_mensagem(e));
    }
  }

  /// Manda o e-mail de redefinição para quem esqueceu a senha.
  ///
  /// Só funciona para quem cadastrou um e-mail de verdade: o Firebase manda a
  /// mensagem para o endereço da conta, e o apelido@domínio interno não existe
  /// como caixa postal.
  Future<String> enviarRedefinicaoDeSenha(String username) async {
    final erro = validarUsuario(username);
    if (erro != null) throw AppException(erro);

    String? destino;
    try {
      final mapa = await _refs.username(normalizarUsuario(username)).get();
      final dados = mapa.data();
      for (final campo in ['authEmail', 'pendingEmail']) {
        final valor = dados?[campo];
        if (valor is String && !valor.endsWith('@$_dominio')) {
          destino = valor;
          break;
        }
      }
    } catch (_) {
      throw const AppException('Não consegui consultar agora. Tente de novo.');
    }

    if (destino == null) {
      throw const AppException(
        'Esse usuário não tem e-mail de recuperação cadastrado. Quem souber a '
        'senha pode entrar e cadastrar um em Editar perfil.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: destino);
      return destino;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mensagem(e));
    }
  }

  /// Cria a conta e, na sequência, o perfil no Firestore.
  ///
  /// Quem cria a família vira o primeiro integrante; os outros entram com o
  /// código do convite.
  Future<AppUser> signUp({
    required String name,
    required String username,
    required String password,
    required String role,
    required String avatarEmoji,
    required int avatarColor,
    String? familyName,
    String? inviteCode,
  }) async {
    final erroUsuario = validarUsuario(username);
    if (erroUsuario != null) throw AppException(erroUsuario);

    if (password.length < minSenha) {
      throw const AppException(
        'A senha precisa de pelo menos $minSenha caracteres.',
      );
    }
    if (name.trim().length < 2) {
      throw const AppException('Digite seu nome.');
    }
    if ((familyName == null || familyName.trim().isEmpty) &&
        (inviteCode == null || inviteCode.trim().isEmpty)) {
      throw const AppException(
        'Crie uma família nova ou informe o código do convite.',
      );
    }

    final usuario = normalizarUsuario(username);

    final UserCredential credencial;
    try {
      credencial = await _auth.createUserWithEmailAndPassword(
        email: _emailDe(usuario),
        password: _senhaReal(password),
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_mensagem(e, usuario: usuario));
    }

    final uid = credencial.user!.uid;
    await credencial.user!.updateDisplayName(name.trim());

    var user = AppUser(
      id: uid,
      familyId: '',
      displayName: name.trim(),
      username: usuario,
      role: role,
      avatarEmoji: avatarEmoji,
      avatarColor: avatarColor,
    );

    await _refs.user(uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // O mapa apelido → conta nasce junto. É o que a tela de entrada consulta
    // antes de existir sessão, e o que permite trocar o e-mail da conta depois
    // sem perder o login por apelido.
    await _anotarMapa(usuario: usuario, conta: credencial.user);

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

  /// Troca a senha de quem já está dentro. É a única "recuperação" possível
  /// sem e-mail: quem lembra a senha atual consegue mudar.
  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AppException('Você precisa estar conectado.');
    }
    if (novaSenha.length < minSenha) {
      throw const AppException(
        'A senha precisa de pelo menos $minSenha caracteres.',
      );
    }
    try {
      // Reautentica antes: o Firebase exige sessão recente para trocar senha.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: email,
          password: _senhaReal(senhaAtual),
        ),
      );
      await user.updatePassword(_senhaReal(novaSenha));
    } on FirebaseAuthException catch (e) {
      throw AppException(_mensagem(e));
    }
  }

  String _mensagem(FirebaseAuthException e, {String? usuario}) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Usuário ou senha incorretos.';
      case 'email-already-in-use':
        return usuario == null
            ? 'Esse usuário já existe. Faça login.'
            : 'O usuário "$usuario" já existe. Escolha outro.';
      case 'weak-password':
        return 'A senha precisa de pelo menos $minSenha caracteres.';
      case 'network-request-failed':
        return 'Sem conexão. Tente de novo.';
      case 'too-many-requests':
        return 'Muitas tentativas. Espere um pouco e tente de novo.';
      case 'invalid-email':
        return 'Usuário inválido. Use letras, números, ponto ou hífen.';
      default:
        return e.message ?? 'Não foi possível concluir. Tente de novo.';
    }
  }
}
