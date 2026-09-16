import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../models/feed_post.dart';
import '../../state/session_controller.dart';
import '../../widgets/donate_points_sheet.dart';
import '../../widgets/members_group.dart';
import '../../widgets/pending_sync_banner.dart';
import '../../widgets/publish_card_sheet.dart';
import '../../widgets/rewards_group.dart';
import '../../widgets/ui/inset_group.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/vault_progress_card.dart';
import '../family/family_settings_screen.dart';
import '../profile/member_profile_screen.dart';
import '../profile/profile_edit_screen.dart';

/// TELA 1 — A Casa.
///
/// Organizada em blocos, no formato dos Ajustes do iOS: o cofre em destaque,
/// a ação principal logo abaixo, e o resto em grupos por assunto. Dá para
/// varrer a tela de cima a baixo sem parar para entender cada pedaço.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onRegisterActivity});

  final VoidCallback? onRegisterActivity;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final family = session.family;
    final user = session.user;

    if (family == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            Space.huge,
          ),
          children: [
            _Cabecalho(nome: user.firstName, familia: family.name),
            const SizedBox(height: Space.xl),

            const PendingSyncBanner(),
            VaultProgressCard(family: family),
            const SizedBox(height: Space.lg),

            Pressable(
              onPressed: onRegisterActivity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: Space.sm),
                  Text(
                    'Registrar atividade',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),

            MembersGroup(
              members: session.members,
              totalMembros: family.memberIds.length,
              onMemberTap: (m) => MemberProfileScreen.open(context, m.id),
            ),
            const SizedBox(height: Space.xl),

            RewardsGroup(
              rewards: family.rewards,
              vaultPoints: family.vaultPoints,
            ),
            const SizedBox(height: Space.xl),

            _GrupoCartas(saveCards: user.cartasDisponiveis),
            const SizedBox(height: Space.xl),

            _GrupoConta(streak: user.currentStreak),
          ],
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.nome, required this.familia});

  final String nome;
  final String familia;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(familia.toUpperCase(), style: t.labelMedium),
              const SizedBox(height: 2),
              Text('Olá, $nome', style: t.headlineMedium),
            ],
          ),
        ),
        const _BotaoTema(),
      ],
    );
  }
}

class _BotaoTema extends StatelessWidget {
  const _BotaoTema();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tema = context.watch<ThemeController>();
    final escuro = tema.isDark(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        tema.alternar(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.group),
          border: Border.all(color: p.border),
        ),
        child: Icon(
          escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 19,
          color: p.textSecondary,
        ),
      ),
    );
  }
}

/// As três cartas como linhas, não como cartões espremidos.
///
/// Em linha cabe o nome e a explicação do que a carta faz — quem nunca usou
/// entende sem precisar perguntar.
class _GrupoCartas extends StatelessWidget {
  const _GrupoCartas({required this.saveCards});

  final int saveCards;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InsetGroup(
      header: 'Cartas de brincadeira',
      footer: 'A carta Salva-Mãe/Pai volta toda segunda-feira.',
      children: [
        InsetRow(
          icon: Icons.volunteer_activism_outlined,
          tint: p.accent,
          title: 'Salva-Mãe / Salva-Pai',
          subtitle: saveCards > 0
              ? 'doe pontos — quem recebe leva o dobro'
              : 'você já usou a desta semana',
          value: saveCards > 0 ? '$saveCards' : null,
          onTap: saveCards > 0 ? () => DonatePointsSheet.show(context) : null,
        ),
        InsetRow(
          icon: Icons.local_fire_department_outlined,
          tint: p.energy,
          title: 'Desafio Impossível',
          subtitle: 'mini-desafio relâmpago para o grupo',
          onTap: () => PublishCardSheet.show(
            context,
            FeedPostType.impossibleChallenge,
          ),
        ),
        InsetRow(
          icon: Icons.theater_comedy_outlined,
          title: 'Punição Leve',
          subtitle: 'a prenda de domingo de quem fez menos',
          onTap: () => PublishCardSheet.show(context, FeedPostType.punishment),
        ),
      ],
    );
  }
}

class _GrupoConta extends StatelessWidget {
  const _GrupoConta({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final session = context.read<SessionController>();

    return InsetGroup(
      header: 'Você e a família',
      children: [
        InsetRow(
          icon: Icons.timeline_rounded,
          title: 'Meu progresso',
          subtitle: streak > 0
              ? 'sequência de $streak ${streak == 1 ? 'dia' : 'dias'}'
              : 'histórico e últimos 7 dias',
          trailing: streak > 0
              ? Icon(Icons.local_fire_department_rounded,
                  size: 18, color: p.energy)
              : null,
          onTap: () {
            final id = session.user?.id;
            if (id != null) MemberProfileScreen.open(context, id);
          },
        ),
        InsetRow(
          icon: Icons.face_retouching_natural_rounded,
          title: 'Editar meu perfil',
          subtitle: 'foto, nome que aparece e cor',
          onTap: () => ProfileEditScreen.open(context),
        ),
        InsetRow(
          icon: Icons.tune_rounded,
          title: 'Ajustes da família',
          subtitle: 'meta da semana e foto comprovante',
          onTap: () => FamilySettingsScreen.open(context),
        ),
        InsetRow(
          icon: Icons.ios_share_rounded,
          title: 'Convidar alguém',
          subtitle: 'copiar o código da família',
          onTap: () {
            final code = session.family?.inviteCode ?? '';
            Clipboard.setData(ClipboardData(text: code));
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Código $code copiado')),
            );
          },
        ),
        InsetRow(
          icon: Icons.logout_rounded,
          tint: p.danger,
          title: 'Sair da conta',
          showChevron: false,
          onTap: session.signOut,
        ),
      ],
    );
  }
}
