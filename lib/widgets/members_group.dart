import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/utils/formatters.dart';
import '../models/app_user.dart';
import 'avatar_bubble.dart';
import 'ui/inset_group.dart';

/// Os integrantes num grupo só, com a fatia de cada um.
class MembersGroup extends StatelessWidget {
  const MembersGroup({
    super.key,
    required this.members,
    required this.totalMembros,
    this.onMemberTap,
  });

  final List<AppUser> members;
  final int totalMembros;
  final ValueChanged<AppUser>? onMemberTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    if (members.isEmpty) {
      return const InsetGroup(
        header: 'A turma',
        children: [
          InsetRow(
            icon: Icons.person_add_alt_outlined,
            title: 'Convide a família',
            subtitle: 'compartilhe o código do convite',
            showChevron: false,
          ),
        ],
      );
    }

    return InsetGroup(
      header: 'A turma esta semana',
      trailing: Text('$totalMembros de 4', style: t.bodySmall),
      children: [
        for (final m in members)
          InsetRow(
            leading: AvatarBubble(user: m, size: 38),
            title: m.firstName,
            subtitle: m.isActiveToday
                ? (m.statusMessage.isNotEmpty
                    ? m.statusMessage
                    : 'treinou hoje')
                : 'ainda não treinou hoje',
            onTap: onMemberTap == null ? null : () => onMemberTap!(m),
            trailing: _Fatia(
              pontos: m.pointsThisWeek,
              ativo: m.isActiveToday,
            ),
          ),
      ],
    );
  }
}

/// Pontos da semana do integrante.
///
/// Só o número: a barrinha que havia aqui lia como um sublinhado solto ao
/// lado do valor, e a comparação entre membros já aparece na ordem da lista.
class _Fatia extends StatelessWidget {
  const _Fatia({required this.pontos, required this.ativo});

  final int pontos;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Text(
      Formatters.points(pontos),
      style: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: ativo ? p.accent : p.textSecondary,
      ),
    );
  }
}
