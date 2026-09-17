import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed_post.dart';
import '../services/avisos/avisos.dart';
import '../services/feed_service.dart';

/// Liga os avisos do aparelho ao mural da família.
///
/// Fica no nível do app, e não dentro da tela do mural, porque o ponto é
/// justamente avisar quem NÃO está olhando o mural.
class AvisosController extends ChangeNotifier {
  AvisosController(this._feed);

  final FeedService _feed;

  static const String _chave = 'avisos_ligados_v1';

  StreamSubscription<List<FeedPost>>? _assinatura;
  String? _familiaObservada;
  String? _meuId;

  bool _ligados = false;
  bool _carregado = false;

  /// Ids já anunciados. Sem isto, qualquer reemissão do stream — uma reação
  /// nova num post antigo, por exemplo — reanunciaria a lista inteira.
  ///
  /// Podado em [_aoChegar]: a consulta traz 8 posts, então lembrar muito mais
  /// que isso é só memória parada crescendo enquanto o app fica aberto.
  final Set<String> _jaAvisados = {};

  static const int _maxLembrados = 40;

  /// A primeira lista que chega é histórico, não novidade. Avisar sobre ela
  /// encheria a tela de avisos de ontem toda vez que alguém abrisse o app.
  bool _primeiraLeitura = true;

  bool get ligados => _ligados;
  bool get suportado => avisosSuportados;
  bool get bloqueadoPeloNavegador => avisosPermissao == 'denied';

  Future<void> carregar() async {
    if (_carregado) return;
    _carregado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _ligados = (prefs.getBool(_chave) ?? false) && avisosPermissao == 'granted';
    } catch (_) {
      _ligados = false;
    }
    notifyListeners();
  }

  /// Liga os avisos, pedindo a permissão ao navegador se ainda não houver.
  ///
  /// Devolve `false` quando a pessoa recusou — aí a interface explica que a
  /// liberação agora é no cadeado da barra de endereço, porque o navegador não
  /// deixa perguntar de novo.
  Future<bool> ligar() async {
    if (!avisosSuportados) return false;
    var permissao = avisosPermissao;
    if (permissao == 'default') {
      permissao = await pedirPermissaoDeAvisos();
    }
    _ligados = permissao == 'granted';
    await _guardar();
    _assinar();
    notifyListeners();
    return _ligados;
  }

  Future<void> desligar() async {
    _ligados = false;
    await _guardar();
    _assinar();
    notifyListeners();
  }

  Future<void> _guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chave, _ligados);
    } catch (_) {
      // Sem armazenamento local a escolha vale só nesta sessão.
    }
  }

  /// Chamado pela sessão quando a família ou a pessoa muda.
  void observar({required String? familyId, required String? meuId}) {
    _meuId = meuId;
    if (familyId == _familiaObservada && _assinatura != null) return;
    _familiaObservada = familyId;
    _assinar();
  }

  /// Liga (ou desliga) o ouvinte do mural.
  ///
  /// Este é um SEGUNDO ouvinte da mesma consulta — o primeiro é a tela do
  /// mural. Desde que a foto passou a viajar dentro do documento, cada post
  /// carrega dezenas de KB, e manter este ouvinte de pé com os avisos
  /// desligados baixaria tudo isso de novo, à toa, no plano gratuito. Então
  /// ele só existe quando há mesmo um aviso para dar.
  void _assinar() {
    _assinatura?.cancel();
    _assinatura = null;
    _jaAvisados.clear();
    _primeiraLeitura = true;

    final familyId = _familiaObservada;
    if (familyId == null || familyId.isEmpty) return;
    if (!avisosSuportados || !_ligados) return;

    // Poucos posts: o objetivo é só pegar o que chegou agora, não a lista.
    _assinatura = _feed.watchFeed(familyId, limit: 8).listen(
          _aoChegar,
          onError: (_) {/* mural indisponível não é assunto de aviso */},
        );
  }

  void _aoChegar(List<FeedPost> posts) {
    if (_primeiraLeitura) {
      _primeiraLeitura = false;
      for (final post in posts) {
        _jaAvisados.add(post.id);
      }
      return;
    }
    for (final post in posts.reversed) {
      if (_jaAvisados.contains(post.id)) continue;
      _jaAvisados.add(post.id);
      if (post.authorId == _meuId) continue; // o próprio registro não avisa
      mostrarAviso(
        titulo: _titulo(post),
        corpo: post.message,
        tag: 'mural',
        icone: 'icons/Icon-192.png',
      );
    }

    if (_jaAvisados.length > _maxLembrados) {
      // Guarda os ids da página atual, que são os únicos que podem voltar.
      final atuais = posts.map((p) => p.id).toSet();
      _jaAvisados
        ..removeWhere((id) => !atuais.contains(id))
        ..addAll(atuais);
    }
  }

  String _titulo(FeedPost post) {
    final nome = post.authorName.split(' ').first;
    switch (post.type) {
      case FeedPostType.activity:
        return post.points > 0
            ? '$nome treinou · +${post.points} pts'
            : '$nome treinou';
      case FeedPostType.saveCard:
        return '$nome usou a carta Salva-Mãe/Pai';
      case FeedPostType.impossibleChallenge:
        return 'Desafio Impossível de $nome';
      case FeedPostType.punishment:
        return 'Punição de $nome';
      case FeedPostType.rewardUnlocked:
        return 'Prêmio liberado!';
      case FeedPostType.system:
        return 'Desafio em Família';
    }
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }
}
