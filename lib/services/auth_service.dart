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

  /// O e-mail real da conta, segundo o mapa — ou `null` se ela nunca trocou.
  ///
  /// Prefere `authEmail`, que é reescrito a cada login com o endereço que o
  /// Firebase realmente usa. `pendingEmail` só entra quando `authEmail` ainda
  /// é o interno: é a janela entre a pessoa confirmar a troca pelo link e o
  /// primeiro login depois disso, quando o mapa ainda não sabe da mudança.
  Future<String?> _emailRealDe(String usuario) async {
    try {
      final mapa = await _refs.username(normalizarUsuario(usuario)).get();
      final dados = mapa.data();
      if (dados == null) return null;
      for (final campo in ['authEmail', 'pendingEmail']) {
        final valor = dados[campo];
        if (valor is String && valor.isNotEmpty && !_ehInterno(valor)) {
          return valor;
        }
      }
    } catch (_) {
      // Mapa indisponível não pode impedir o login normal.
    }
    return null;
  }

  static bool _ehInterno(String email) => email.endsWith('@$_dominio');

  /// Erros que só significam "essa combinação não é a certa" — os únicos em
  /// que vale tentar a próxima. Conta desativada, rede fora ou excesso de
  /// tentativas não melhoram insistindo, e insistir piora o excesso.
  static const Set<String> _errosDeCredencial = {
    'user-not-found',
    'wrong-password',
    'invalid-credential',
    'invalid-login-credentials',
  };

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final erro = validarUsuario(username);
    if (erro != null) throw AppException(erro);

    // No máximo três tentativas, e uma só no caso comum.
    //
    // Cada tentativa falha conta para o limite do Firebase, que bloqueia a
    // conta por um tempo depois de algumas — com a combinação de todos os
    // e-mails contra todas as senhas, dois erros de digitação bastavam para
    // trancar a pessoa para fora. Por isso o caminho de sempre vem primeiro e
    // sozinho, e o resto só entra se houver e-mail real cadastrado.
    final padrao = _emailDe(username);
    final tentativa = await _tentar(padrao, _senhaReal(password), username);
    if (tentativa) return;

    final real = await _emailRealDe(username);
    if (real != null && real != padrao) {
      if (await _tentar(real, _senhaReal(password), username)) return;
      // A senha crua só faz sentido aqui: quem redefiniu pelo link do e-mail
      // digitou a senha na página do Firebase, que não conhece o sufixo — e
      // redefinir por link exige justamente ter e-mail real.
      if (await _tentar(real, password, username, crua: true)) return;
    }

    throw AppException(_mensagem(
      _ultimoErro ?? FirebaseAuthException(code: 'invalid-credential'),
    ));
  }

  FirebaseAuthException? _ultimoErro;

  /// Uma tentativa de entrada. `true` se entrou; `false` se foi só credencial
  /// errada. Qualquer outro erro sobe na hora, sem gastar outra tentativa.
  Future<bool> _tentar(
    String email,
    String senha,
    String usuario, {
    bool crua = false,
  }) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      if (crua) {
        // Devolve a conta à convenção do app, para a pessoa seguir digitando
        // a mesma coisa e cair no caminho curto na próxima vez.
        try {
          await credencial.user?.updatePassword(_senhaReal(senha));
        } catch (_) {
          // Se não der, o login desta vez já valeu e a próxima repete por aqui.
        }
      }
      await _anotarMapa(usuario: usuario, conta: credencial.user);
      _ultimoErro = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _ultimoErro = e;
      if (!_errosDeCredencial.contains(e.code)) {
        throw AppException(_mensagem(e));
      }
      return false;
    }
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
    if (email == null || _ehInterno(email)) return null;
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
    if (_ehInterno(limpo.toLowerCase())) {
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
    String? pendente;
    try {
      final mapa = await _refs.username(normalizarUsuario(username)).get();
      final dados = mapa.data();
      final autenticado = dados?['authEmail'];
      if (autenticado is String && !_ehInterno(autenticado)) {
        destino = autenticado;
      }
      final aguardando = dados?['pendingEmail'];
      if (aguardando is String && !_ehInterno(aguardando)) {
        pendente = aguardando;
      }
    } catch (_) {
      throw const AppException('Não consegui consultar agora. Tente de novo.');
    }

    // Só o e-mail JÁ confirmado serve. Mandar para um que ainda aguarda
    // confirmação falha no Firebase, que ainda não conhece aquele endereço, e
    // a pessoa receberia "usuário ou senha incorretos" — beco sem saída bem na
    // hora em que ela mais precisa de uma instrução clara.
    if (destino == null && pendente != null) {
      throw const AppException(
        'O e-mail cadastrado ainda não foi confirmado. Procure a mensagem de '
        'confirmação do Firebase na caixa de entrada e clique no link.',
      );
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
