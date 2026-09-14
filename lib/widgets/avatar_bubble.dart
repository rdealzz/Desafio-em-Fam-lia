import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/app_user.dart';

/// Avatar circular do integrante, com anel de status do dia.
///
/// Anel verde = já registrou atividade hoje. Cinza = ainda não.
class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    super.key,
    required this.user,
    this.size = 60,
    this.showRing = true,
    this.onTap,
  });

  final AppUser user;
  final double size;
  final bool showRing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = user.isActiveToday;
    final ringColor = active ? AppColors.success : const Color(0xFFD9D6E8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showRing
              ? Border.all(color: ringColor, width: 3)
              : Border.all(color: Colors.transparent),
        ),
        child: ClipOval(
          child: user.photoUrl != null && user.photoUrl!.isNotEmpty
              ? Image.network(
                  user.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _EmojiAvatar(
                    emoji: user.avatarEmoji,
                    size: size,
                  ),
                )
              : _EmojiAvatar(emoji: user.avatarEmoji, size: size),
        ),
      ),
    );
  }
}

class _EmojiAvatar extends StatelessWidget {
  const _EmojiAvatar({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.10),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}
