import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/firestore_utils.dart';
import '../core/utils/formatters.dart';
import '../models/feed_post.dart';
import 'ui/primitives.dart';

/// Publicação do mural.
///
/// Foto em destaque, texto sóbrio, reações discretas. As cartas de brincadeira
/// ganham uma faixa fina no topo em vez de contorno colorido no cartão inteiro
/// — sinaliza o tipo sem transformar o feed num mostruário de cores.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onReaction,
  });

  final FeedPost post;
  final String currentUserId;
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final temFoto = post.photoUrl != null && post.photoUrl!.isNotEmpty;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isCard) _Faixa(post: post),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.lg,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: p.surfaceSunken,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      post.authorAvatar,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelLarge,
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          post.createdAt == null
                              ? 'agora'
                              : Formatters.timeAgo(post.createdAt!),
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (post.points > 0)
                    Text(
                      '+${Formatters.points(post.points)}',
                      style: t.labelLarge?.copyWith(
                        color: p.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            if (post.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  0,
                ),
                child: Text(post.message, style: t.bodyLarge),
              ),
            if (post.durationMinutes > 0 || post.metadata['offlineSync'] == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  0,
                ),
                child: Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    if (post.durationMinutes > 0)
                      MetaChip(
                        icon: Icons.schedule_rounded,
                        label: Formatters.duration(post.durationMinutes),
                      ),
                    if (_num(post.metadata['steps']) > 0)
                      MetaChip(
                        icon: Icons.directions_walk_rounded,
                        label: '${_num(post.metadata['steps'])} passos',
                      ),
                    if (_num(post.metadata['streak']) > 1)
                      MetaChip(
                        icon: Icons.bolt_rounded,
                        label: '${_num(post.metadata['streak'])} dias',
                      ),
                    if (post.metadata['offlineSync'] == true)
                      MetaChip(
                        icon: Icons.cloud_done_outlined,
                        label: _rotuloOffline(post),
                      ),
                  ],
                ),
              ),
            if (temFoto) ...[
              const SizedBox(height: Space.md),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  post.photoUrl!,
                  fit: BoxFit.cover,
                  // Decodifica em ~2x a largura de tela, não no tamanho
                  // original da câmera: corta memória e trabalho de GPU.
                  cacheWidth: 900,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : ColoredBox(color: p.surfaceSunken),
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: p.surfaceSunken),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                Space.md,
              ),
              child: Row(
                children: [
                  for (final e in Reactions.available.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.sm),
                      child: _Reacao(
                        emoji: e.value,
                        count: post.reactionCount(e.key),
                        ativa: post.hasReacted(e.key, currentUserId),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReaction(e.key);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _num(Object? v) => v is num ? v.toInt() : 0;

  static String _rotuloOffline(FeedPost post) {
    final at = FirestoreUtils.toDateTime(post.metadata['performedAt']);
    return at == null ? 'offline' : 'feito ${Formatters.timeAgo(at)}';
  }
}

class _Reacao extends StatelessWidget {
  const _Reacao({
    required this.emoji,
    required this.count,
    required this.ativa,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool ativa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 6),
        decoration: BoxDecoration(
          color: ativa ? p.accentSoft : p.surfaceSunken,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: ativa ? p.accent : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ativa ? p.accent : p.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Faixa extends StatelessWidget {
  const _Faixa({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cor = switch (post.type) {
      FeedPostType.impossibleChallenge => p.warning,
      FeedPostType.punishment => p.danger,
      _ => p.accent,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cor, width: 2)),
      ),
      child: Text(
        switch (post.type) {
          FeedPostType.saveCard => 'CARTA SALVA-MÃE/PAI',
          FeedPostType.impossibleChallenge => 'DESAFIO IMPOSSÍVEL',
          FeedPostType.punishment => 'PUNIÇÃO LEVE',
          _ => 'AVISO',
        },
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: cor, fontWeight: FontWeight.w800),
      ),
    );
  }
}
