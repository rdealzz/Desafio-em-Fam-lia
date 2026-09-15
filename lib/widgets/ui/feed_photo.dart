import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// Foto do mural que **some** quando não carrega.
///
/// Com `AspectRatio` + `errorBuilder`, uma foto que falha deixa um retângulo
/// cinza enorme no meio do feed — o espaço fica reservado mesmo sem imagem.
/// Aqui o estado de erro remove o widget inteiro: melhor um post sem foto do
/// que um buraco cinza de meia tela.
class FeedPhoto extends StatefulWidget {
  const FeedPhoto({super.key, required this.url});

  final String url;

  @override
  State<FeedPhoto> createState() => _FeedPhotoState();
}

class _FeedPhotoState extends State<FeedPhoto> {
  bool _falhou = false;

  @override
  Widget build(BuildContext context) {
    if (_falhou) return const SizedBox.shrink();
    final p = context.palette;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Image.network(
        widget.url,
        fit: BoxFit.cover,
        // Decodifica em ~2x a largura de tela, não no tamanho da câmera.
        cacheWidth: 900,
        loadingBuilder: (context, child, progresso) =>
            progresso == null ? child : ColoredBox(color: p.surfaceSunken),
        errorBuilder: (_, __, ___) {
          // Agenda para depois do quadro: chamar setState durante a
          // construção lança exceção.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_falhou) setState(() => _falhou = true);
          });
          return ColoredBox(color: p.surfaceSunken);
        },
      ),
    );
  }
}
