import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../services/activity_sync_service.dart';
import '../state/session_controller.dart';
import 'ui/primitives.dart';

/// Aviso do que está guardado no celular esperando internet.
class PendingSyncBanner extends StatelessWidget {
  const PendingSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<ActivitySyncService>();
    if (!sync.hasPending) return const SizedBox.shrink();

    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final total = sync.pendingCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Surface(
        color: p.surfaceRaised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 17, color: p.warning),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    total == 1
                        ? '1 atividade esperando internet'
                        : '$total atividades esperando internet',
                    style: t.labelLarge,
                  ),
                ),
                if (sync.syncing)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      final user = context.read<SessionController>().user;
                      if (user != null) sync.drain(user);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'tentar agora',
                      style: t.bodySmall?.copyWith(
                        color: p.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Sobem sozinhas quando a conexão voltar. Não registre de novo — '
              'os pontos contariam em dobro.',
              style: t.bodySmall,
            ),
            const SizedBox(height: Space.md),
            for (final item in sync.pending.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${item.type.label} · '
                  '${Formatters.duration(item.durationMinutes)} · '
                  '${Formatters.timeAgo(item.performedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: p.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
