import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/feed_post.dart';

/// Post do Mural do Deboche & Apoio: autor, foto, tempo, pontos e reações.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onReaction,
  });

  final FeedPost post;
  final String currentUserId;

  /// Recebe a chave da reação (`fire`, `laugh`...) tocada.
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(post.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: post.isCard ? accent.withOpacity(0.4) : const Color(0xFFEFEDF7),
          width: post.isCard ? 1.8 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isCard) _CardBanner(post: post, accent: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: accent.withOpacity(0.14),
                  backgroundImage: (post.authorPhotoUrl?.isNotEmpty ?? false)
                      ? NetworkImage(post.authorPhotoUrl!)
                      : null,
                  child: (post.authorPhotoUrl?.isNotEmpty ?? false)
                      ? null
                      : Text(
                          post.authorAvatar,
                          style: const TextStyle(fontSize: 20),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        post.createdAt == null
                            ? 'agora'
                            : Formatters.timeAgo(post.createdAt!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.points > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '+${Formatters.points(post.points)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (post.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                post.message,
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ),
          if (post.durationMinutes > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: [
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: Formatters.duration(post.durationMinutes),
                  ),
                  if ((post.metadata['steps'] as num?) != null &&
                      (post.metadata['steps'] as num) > 0)
                    _Chip(
                      icon: Icons.directions_walk,
                      label: '${post.metadata['steps']} passos',
                    ),
                  if ((post.metadata['streak'] as num?) != null &&
                      (post.metadata['streak'] as num) > 1)
                    _Chip(
                      icon: Icons.local_fire_department,
                      label: '${post.metadata['streak']} dias seguidos',
                    ),
                ],
              ),
            ),
          if (post.photoUrl != null && post.photoUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                post.photoUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const ColoredBox(
                        color: Color(0xFFF1EFFA),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFF1EFFA),
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: Reactions.available.entries.map((entry) {
                final reacted = post.hasReacted(entry.key, currentUserId);
                final count = post.reactionCount(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onReaction(entry.key),
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: reacted
                            ? AppColors.primary.withOpacity(0.12)
                            : const Color(0xFFF6F5FB),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: reacted
                              ? AppColors.primary.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(entry.value,
                              style: const TextStyle(fontSize: 15)),
                          if (count > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: reacted
                                    ? AppColors.primary
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Color _accentFor(FeedPostType type) {
    switch (type) {
      case FeedPostType.saveCard:
        return AppColors.primary;
      case FeedPostType.impossibleChallenge:
        return AppColors.danger;
      case FeedPostType.punishment:
        return AppColors.warning;
      case FeedPostType.rewardUnlocked:
        return AppColors.success;
      case FeedPostType.activity:
      case FeedPostType.system:
        return AppColors.primary;
    }
  }
}

/// Faixa que identifica a carta de brincadeira no topo do post.
class _CardBanner extends StatelessWidget {
  const _CardBanner({required this.post, required this.accent});

  final FeedPost post;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accent.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Text(post.type.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text(
            _labelFor(post.type),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(FeedPostType type) {
    switch (type) {
      case FeedPostType.saveCard:
        return 'CARTA SALVA-MÃE/PAI';
      case FeedPostType.impossibleChallenge:
        return 'DESAFIO IMPOSSÍVEL';
      case FeedPostType.punishment:
        return 'PUNIÇÃO LEVE — PAGANDO MICO';
      default:
        return 'AVISO';
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5FB),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkSoft),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
