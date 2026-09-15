import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/activity_sync_service.dart';
import '../state/session_controller.dart';

/// Aviso do que está guardado no celular esperando internet.
///
/// Só aparece quando há pendência. A pessoa precisa saber que o esforço não
/// se perdeu — sem isso, ela registra de novo e os pontos contam em dobro.
class PendingSyncBanner extends StatelessWidget {
  const PendingSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<ActivitySyncService>();
    if (!sync.hasPending) return const SizedBox.shrink();

    final total = sync.pendingCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.warning.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  total == 1
                      ? '1 atividade esperando internet'
                      : '$total atividades esperando internet',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Color(0xFF8A6A00),
                  ),
                ),
              ),
              if (sync.syncing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Entram no cofre sozinhas assim que a conexão voltar. '
            'Não registre de novo — os pontos contariam em dobro.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: const Color(0xFF8A6A00).withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in sync.pending.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(item.type.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.type.label} • '
                      '${Formatters.duration(item.durationMinutes)} • '
                      '${Formatters.timeAgo(item.performedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A6A00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (total > 3)
            Text(
              'e mais ${total - 3}…',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A6A00)),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: sync.syncing
                  ? null
                  : () {
                      final user = context.read<SessionController>().user;
                      if (user != null) sync.drain(user);
                    },
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Tentar agora'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8A6A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
