import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_user.dart';
import 'avatar_bubble.dart';

/// Faixa com os 4 integrantes e o status de cada um no dia.
///
/// Ex.: "Mãe — Já fez a caminhada!" / "Pai — ainda não treinou hoje".
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
      return const _EmptyMembers();
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final member = members[index];
          return _MemberTile(
            member: member,
            onTap: onMemberTap == null ? null : () => onMemberTap!(member),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, this.onTap});

  final AppUser member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = member.isActiveToday;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.success.withOpacity(0.35)
                : const Color(0xFFEFEDF7),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarBubble(user: member, size: 54),
            const SizedBox(height: 8),
            Text(
              member.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${Formatters.points(member.pointsThisWeek)} pts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              active ? '✅ treinou hoje' : '⏳ ainda não',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: active ? AppColors.success : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Convide os outros 3 integrantes para começar 👨‍👩‍👦',
        style: TextStyle(color: AppColors.inkSoft),
      ),
    );
  }
}
