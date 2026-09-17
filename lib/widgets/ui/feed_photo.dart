import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../models/feed_post.dart';
import '../../services/photo_proof.dart';

/// Foto do mural que **some** quando não carrega.
///
/// Com `AspectRatio` + `errorBuilder`, uma foto que falha deixa um retângulo
/// cinza enorme no meio do feed — o espaço fica reservado mesmo sem imagem.
/// Aqui o estado de erro remove o widget inteiro: melhor um post sem foto do
/// que um buraco cinza de meia tela.
///
/// Atende as duas origens: a foto nova, em base64 dentro do documento, e a
/// antiga, no Storage por endereço.
class FeedPhoto extends StatefulWidget {
  const FeedPhoto({super.key, this.dados, this.url})
      : assert(dados != null || url != null, 'precisa de dados ou endereço');

  /// A foto ainda em base64. A decodificação acontece no estado, uma vez por
  /// post — ver [_FeedPhotoState._decodificar].
  final String? dados;
  final String? url;

  /// Decide o que mostrar para um post, ou `null` quando não há foto válida.
  ///
  /// Foto vencida não aparece nem quando os bytes ainda estão no documento: a
  /// limpeza acontece quando alguém abre o app, e até lá o combinado de um dia
  /// tem de valer mesmo assim.
  ///
  /// A chave é o id do post porque o Flutter reaproveita o estado por posição
  /// na lista: sem ela, uma foto quebrada marcava a posição, e o post que
  /// depois ocupasse aquela posição aparecia sem a foto dele.
  static FeedPhoto? para(FeedPost post) {
    if (!PhotoProof.venceu(post.photoExpiresAt)) {
      final dados = post.photoData;
      if (dados != null && dados.isNotEmpty) {
        return FeedPhoto(key: ValueKey('foto-${post.id}'), dados: dados);
      }
    }
    final url = post.photoUrl;
    if (url != null && url.isNotEmpty) {
      return FeedPhoto(key: ValueKey('foto-${post.id}'), url: url);
    }
    return null;
  }

  @override
  State<FeedPhoto> createState() => _FeedPhotoState();
}

class _FeedPhotoState extends State<FeedPhoto> {
  bool _falhou = false;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decodificar();
  }

  @override
  void didUpdateWidget(FeedPhoto anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.dados != widget.dados || anterior.url != widget.url) {
      // Conteúdo diferente merece chance nova: sem isto, o estado de falha
      // ficava grudado no lugar mesmo depois de a foto mudar.
      _falhou = false;
      _decodificar();
    }
  }

  /// Decodifica uma vez e guarda os bytes.
  ///
  /// Fazer isso no `build` seria refazer o trabalho a cada quadro — e pior:
  /// `Image.memory` guarda o cache pela identidade da lista de bytes, então
  /// uma lista nova a cada construção nunca acerta o cache e a imagem é
  /// decodificada de novo inteira. No mural, qualquer reação de qualquer um
  /// reconstrói a lista.
  void _decodificar() {
    final dados = widget.dados;
    _bytes = dados == null ? null : PhotoProof.decodificar(dados);
    if (dados != null && _bytes == null) _falhou = true;
  }

  void _marcarFalha() {
    // Agenda para depois do quadro: chamar setState durante a construção
    // lança exceção.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_falhou) setState(() => _falhou = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_falhou) return const SizedBox.shrink();
    final p = context.palette;
    final bytes = _bytes;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: bytes != null
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              // A foto já vem pequena da câmera (400 px); decodificar em
              // 900 não custa e evita borrão em tela grande.
              cacheWidth: 900,
              errorBuilder: (_, __, ___) {
                _marcarFalha();
                return ColoredBox(color: p.surfaceSunken);
              },
            )
          : Image.network(
              widget.url!,
              fit: BoxFit.cover,
              cacheWidth: 900,
              loadingBuilder: (context, child, progresso) =>
                  progresso == null ? child : ColoredBox(color: p.surfaceSunken),
              errorBuilder: (_, __, ___) {
                _marcarFalha();
                return ColoredBox(color: p.surfaceSunken);
              },
            ),
    );
  }
}
