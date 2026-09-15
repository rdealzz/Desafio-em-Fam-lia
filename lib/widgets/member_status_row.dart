import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../models/app_user.dart';
import 'avatar_bubble.dart';
import 'ui/primitives.dart';

/// Os integrantes em lista vertical compacta, com a fatia de cada um.
///
/// Virou lista em vez de carrossel de cartões: com quatro pessoas, rolar na
/// horizontal escondia gente. Vertical mostra todo mundo de uma vez e dá para
/// comparar as barras lado a lado.
class MemberStatusRow extends StatelessWidget {
  const MemberStatusRow({
    super.key,
    required this.members,
    this.onMemberTap,
  });

  final List<AppUser> members;
  final ValueChanged<AppUser>? onMemberTap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Surface(
        child: Text(
          'Convide os outros integrantes para começar.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final maior = members
        .map((m) => m.pointsThisWeek)
        .fold<int>(1, (a, b) => b > a ? b : a);

    return Surface(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: Space.lg, endIndent: Space.lg),
            _Linha(
              member: members[i],
              fracao: members[i].pointsThisWeek / maior,
              onTap: onMemberTap == null
                  ? null
                  : () => onMemberTap!(members[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.member, required this.fracao, this.onTap});

  final AppUser member;
  final double fracao;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final ativo = member.isActiveToday;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
        child: Row(
          children: [
            AvatarBubble(user: member, size: 40),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelLarge,
                        ),
                      ),
                      Text(
                        Formatters.points(member.pointsThisWeek),
                        style: t.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ativo ? p.accent : p.textSecondary,
                          fontFeatures: const [],
                        ),
                      ),
                      Text(' pts', style: t.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ProgressBarThin(
                    value: fracao,
                    height: 4,
                    color: ativo ? p.accent : p.borderStrong,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ativo
                        ? (member.statusMessage.isNotEmpty
                            ? member.statusMessage
                            : 'treinou hoje')
                        : 'ainda não treinou hoje',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
