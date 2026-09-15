import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../models/app_user.dart';

/// Avatar do integrante com anel de status.
///
/// O anel só aparece cheio quem treinou hoje; quem não treinou fica com um
/// traço apagado. Diferença de peso, não de cor berrante.
class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    super.key,
    required this.user,
    this.size = 48,
    this.showRing = true,
  });

  final AppUser user;
  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ativo = user.isActiveToday;
    final anel = ativo ? p.accent : p.border;
    final temFoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(showRing ? 2.5 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showRing
            ? Border.all(color: anel, width: ativo ? 2 : 1.5)
            : null,
      ),
      child: ClipOval(
        child: temFoto
            ? Image.network(
                user.photoUrl!,
                fit: BoxFit.cover,
                // Decodifica no tamanho exibido em vez do tamanho original:
                // menos memória e menos trabalho de GPU por quadro.
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) =>
                    _Inicial(user: user, size: size, palette: p),
              )
            : _Inicial(user: user, size: size, palette: p),
      ),
    );
  }
}

class _Inicial extends StatelessWidget {
  const _Inicial({required this.user, required this.size, required this.palette});

  final AppUser user;
  final double size;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.surfaceSunken,
      child: Center(
        child: Text(
          user.avatarEmoji,
          style: TextStyle(fontSize: size * 0.42),
        ),
      ),
    );
  }
}
