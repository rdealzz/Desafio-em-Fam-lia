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
  const FeedPhoto({super.key, this.bytes, this.url})
      : assert(bytes != null || url != null, 'precisa de bytes ou endereço');

  final Uint8List? bytes;
  final String? url;

  /// Decide o que mostrar para um post, ou `null` quando não há foto válida.
  ///
  /// Foto vencida não aparece nem quando os bytes ainda estão no documento: a
  /// limpeza acontece quando alguém abre o app, e até lá o combinado de um dia
  /// tem de valer mesmo assim.
  static FeedPhoto? para(FeedPost post) {
    if (!PhotoProof.venceu(post.photoExpiresAt)) {
      final bytes = PhotoProof.decodificar(post.photoData);
      if (bytes != null) return FeedPhoto(bytes: bytes);
    }
    final url = post.photoUrl;
    if (url != null && url.isNotEmpty) return FeedPhoto(url: url);
    return null;
  }

  @override
  State<FeedPhoto> createState() => _FeedPhotoState();
}

class _FeedPhotoState extends State<FeedPhoto> {
  bool _falhou = false;

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
    final bytes = widget.bytes;

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
