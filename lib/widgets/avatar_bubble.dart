import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../models/app_user.dart';
import 'ui/avatar_colors.dart';

/// Avatar do integrante: foto, ou iniciais num círculo colorido.
///
/// Iniciais em vez de emoji porque o CanvasKit do Flutter web não usa a fonte
/// de emoji do sistema — no navegador o emoji vira quadradinho. Iniciais
/// sempre renderizam, em qualquer plataforma, e é o que Contatos da Apple,
/// Slack e Gmail fazem.
///
/// O anel cheio marca quem treinou hoje; quem não treinou fica com traço
/// apagado. Diferença de peso, não de cor berrante.
class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    super.key,
    required this.user,
    this.size = 40,
    this.showRing = true,
  });

  final AppUser user;
  final double size;
  final bool showRing;

  /// Até duas letras: "Rosa Maria" vira RM, "Rafael" vira R.
  static String iniciais(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.characters.first.toUpperCase();
    return (partes.first.characters.first + partes.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ativo = user.isActiveToday;
    final temFoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(showRing ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showRing
            ? Border.all(
                // Anel forte em quem treinou hoje, apagado em quem não.
                color: ativo
                    ? AvatarColors.resolver(user.avatarColor, user.id)
                    : p.border,
                width: ativo ? 2 : 1.5,
              )
            : null,
      ),
      child: ClipOval(
        child: temFoto
            ? Image.network(
                user.photoUrl!,
                fit: BoxFit.cover,
                // Decodifica no tamanho exibido, não no original da câmera.
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => _Iniciais(user: user, size: size),
              )
            : _Iniciais(user: user, size: size),
      ),
    );
  }
}

class _Iniciais extends StatelessWidget {
  const _Iniciais({required this.user, required this.size});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cor = AvatarColors.resolver(user.avatarColor, user.id);
    return ColoredBox(
      // Fundo suave da cor escolhida: colorido sem virar bloco chapado.
      color: Color.alphaBlend(cor.withValues(alpha: 0.16), Colors.white),
      child: Center(
        child: Text(
          AvatarBubble.iniciais(user.displayName),
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: cor,
          ),
        ),
      ),
    );
  }
}
