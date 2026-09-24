import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/feed_post.dart';
import '../../services/avisos/avisos.dart';
import '../../services/weekly_standings.dart';
import '../../state/avisos_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/avatar_bubble.dart';
import '../../widgets/donate_points_sheet.dart';
import '../../widgets/members_group.dart';
import '../../widgets/pending_sync_banner.dart';
import '../../widgets/publish_card_sheet.dart';
import '../../widgets/rewards_group.dart';
import '../../widgets/ui/entrada.dart';
import '../../widgets/ui/inset_group.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/vault_progress_card.dart';
import '../family/family_settings_screen.dart';
import '../profile/member_profile_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../scoreboard/scoreboard_screen.dart';

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
            Entrada(
              child: _Cabecalho(nome: user.firstName, familia: family.name),
            ),
            const SizedBox(height: Space.xl),
            const PendingSyncBanner(),
            Entrada(ordem: 1, child: VaultProgressCard(family: family)),
            const SizedBox(height: Space.lg),
            Entrada(
              ordem: 2,
              child: Pressable(
                onPressed: onRegisterActivity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 20),
                    SizedBox(width: Space.sm),
                    Text(
                      'Registrar atividade',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            if (session.members.isNotEmpty)
              Entrada(
                ordem: 3,
                child: _CartaoPlacar(
                  placar: WeeklyStandings.from(session.members),
                ),
              ),
            const SizedBox(height: Space.xxl),
            Entrada(
              ordem: 4,
              child: MembersGroup(
                members: session.members,
                totalMembros: family.memberIds.length,
                onMemberTap: (m) => MemberProfileScreen.open(context, m.id),
              ),
            ),
            const SizedBox(height: Space.xl),
            Entrada(
              ordem: 5,
              child: RewardsGroup(
                rewards: family.rewardsThisWeek,
                vaultPoints: family.vaultThisWeek,
              ),
            ),
            const SizedBox(height: Space.xl),
            Entrada(
              ordem: 6,
              child: _GrupoCartas(saveCards: user.cartasDisponiveis),
            ),
            const SizedBox(height: Space.xl),
            Entrada(
              ordem: 7,
              child: _GrupoConta(streak: user.currentStreak),
            ),
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

  /// Cumprimento pela hora do dia — detalhe pequeno que faz o app parecer
  /// atento, em vez de dizer o mesmo "Olá" às seis da manhã e à meia-noite.
  static String _saudacao(DateTime agora) {
    final h = agora.hour;
    if (h >= 5 && h < 12) return 'Bom dia';
    if (h >= 12 && h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final agora = DateTime.now();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${familia.toUpperCase()}  ·  ${Formatters.dayLabel(agora).toUpperCase()}',
                style: t.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('${_saudacao(agora)}, $nome', style: t.headlineMedium),
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

/// Atalho para o placar: quem puxa a semana, com os avatares do pódio.
///
/// No domingo muda de tom e vira o convite para o fechamento — é o dia de
/// ver quem paga a prenda.
class _CartaoPlacar extends StatelessWidget {
  const _CartaoPlacar({required this.placar});

  final WeeklyStandings placar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final domingo = DateTime.now().weekday == DateTime.sunday;
    final podio = placar.podium;
    final lider = podio.isEmpty ? null : podio.first;

    final titulo = domingo ? 'Fechamento da semana' : 'Placar da semana';
    final subtitulo = lider == null
        ? 'ninguém pontuou ainda — o pódio está vazio'
        : podio.length > 1 && podio[1].position == 1
            ? 'empate no topo com ${Formatters.points(lider.points)} pts'
            : '${lider.member.firstName} puxa a semana com '
                '${Formatters.points(lider.points)} pts';

    return PressableCard(
      onTap: () => ScoreboardScreen.open(context),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Radii.group),
            ),
            child: Icon(Icons.emoji_events_rounded, size: 19, color: p.gold),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: t.titleMedium),
                const SizedBox(height: 1),
                Text(
                  subtitulo,
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (podio.isNotEmpty) ...[
            const SizedBox(width: Space.sm),
            _AvataresSobrepostos(linhas: podio),
          ],
          const SizedBox(width: Space.xs),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}

/// Os avatares do pódio encavalados, com borda da cor do cartão para
/// separar um do outro.
class _AvataresSobrepostos extends StatelessWidget {
  const _AvataresSobrepostos({required this.linhas});

  final List<Standing> linhas;

  static const double _tam = 28;
  static const double _passo = 18;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: _tam + _passo * (linhas.length - 1),
      height: _tam,
      child: Stack(
        children: [
          // O líder por cima: desenhado por último.
          for (var i = linhas.length - 1; i >= 0; i--)
            Positioned(
              left: _passo * i,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.surface, width: 2),
                ),
                child: AvatarBubble(
                  user: linhas[i].member,
                  size: _tam - 4,
                  showRing: false,
                ),
              ),
            ),
        ],
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
          tint: p.warning,
          title: 'Desafio Impossível',
          subtitle: 'mini-desafio relâmpago para o grupo',
          onTap: () => PublishCardSheet.show(
            context,
            FeedPostType.impossibleChallenge,
          ),
        ),
        InsetRow(
          icon: Icons.theater_comedy_outlined,
          tint: p.accentAlt,
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
          tint: p.energy,
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
          tint: p.accentAlt,
          title: 'Editar meu perfil',
          subtitle: 'foto, nome que aparece e cor',
          onTap: () => ProfileEditScreen.open(context),
        ),
        const _LinhaAvisos(),
        InsetRow(
          icon: Icons.tune_rounded,
          tint: p.textMuted,
          title: 'Ajustes da família',
          subtitle: 'meta da semana e foto comprovante',
          onTap: () => FamilySettingsScreen.open(context),
        ),
        InsetRow(
          icon: Icons.ios_share_rounded,
          tint: p.success,
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

/// Liga/desliga os avisos deste aparelho.
///
/// Fica no menu de cada pessoa, e não em Ajustes da família, porque a
/// permissão é do navegador daquele aparelho: ligar no celular não liga no
/// computador, e cada um decide para si.
class _LinhaAvisos extends StatelessWidget {
  const _LinhaAvisos();

  @override
  Widget build(BuildContext context) {
    final avisos = context.watch<AvisosController>();
    final p = context.palette;

    // Navegador sem suporte (ou app nativo): nem mostra a opção, em vez de
    // oferecer uma chave que não faz nada.
    if (!avisos.suportado) return const SizedBox.shrink();

    if (avisos.bloqueadoPeloNavegador) {
      return const InsetRow(
        icon: Icons.notifications_off_outlined,
        title: 'Avisos bloqueados',
        subtitle: 'libere no cadeado da barra de endereço',
        showChevron: false,
      );
    }

    return InsetRow(
      icon: avisos.ligados
          ? Icons.notifications_active_outlined
          : Icons.notifications_none_rounded,
      tint: p.danger,
      title: 'Avisos neste aparelho',
      subtitle: avisos.ligados
          ? 'quando alguém treinar, com o app aberto'
          : 'saber quando alguém da família treinar',
      showChevron: false,
      trailing: Switch.adaptive(
        value: avisos.ligados,
        onChanged: (quer) async {
          final messenger = ScaffoldMessenger.of(context);
          if (!quer) {
            await avisos.desligar();
            return;
          }
          final ok = await avisos.ligar();
          if (!ok) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'O navegador não liberou os avisos. Toque no cadeado da '
                  'barra de endereço para permitir.',
                ),
              ),
            );
          } else {
            HapticFeedback.mediumImpact();
            mostrarAviso(
              titulo: 'Avisos ligados',
              corpo: 'É assim que vou te avisar quando alguém treinar.',
              tag: 'teste',
              icone: 'icons/Icon-192.png',
            );
          }
        },
        activeTrackColor: p.accent,
      ),
    );
  }
}
