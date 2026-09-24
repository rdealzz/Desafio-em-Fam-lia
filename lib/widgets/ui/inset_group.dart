import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

/// Grupo de lista embutida, no formato dos Ajustes do iOS.
///
/// É a peça que organiza o app: título pequeno em caixa alta, itens dentro de
/// um bloco branco arredondado, separadores recuados até onde o texto começa,
/// e um rodapé opcional explicando o grupo. Bloco por assunto em vez de
/// cartões soltos — é o que permite varrer a tela de cima a baixo sem parar
/// para entender cada pedaço.
class InsetGroup extends StatelessWidget {
  const InsetGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.trailing,
    this.dividerIndent = InsetRow.dividerIndent,
  });

  final List<Widget> children;

  /// Onde o separador começa. O padrão acompanha as linhas com ícone.
  final double dividerIndent;
  final String? header;
  final String? footer;

  /// Conteúdo no canto do cabeçalho (contador, ação curta).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(header!.toUpperCase(), style: t.labelMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.card),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    // Recuado até onde o texto começa: o separador organiza
                    // sem cortar a linha inteira.
                    Padding(
                      padding: EdgeInsets.only(left: dividerIndent),
                      child: Divider(
                          height: 1, thickness: 0.5, color: p.borderStrong),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
            child: Text(footer!, style: t.bodySmall),
          ),
      ],
    );
  }
}

/// Uma linha do grupo.
///
/// Ícone à esquerda, texto no meio, valor ou seta à direita — a ordem que o
/// olho já espera. Tocável, responde encolhendo levemente.
class InsetRow extends StatefulWidget {
  const InsetRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.tint,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Space.lg,
      vertical: Space.md,
    ),
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? tint;
  final EdgeInsets padding;

  /// Lado do quadradinho do ícone.
  static const double iconTile = 30;

  /// Recuo do separador numa linha com ícone: começa onde o texto começa.
  static const double dividerIndent = Space.lg + iconTile + Space.md;

  @override
  State<InsetRow> createState() => _InsetRowState();
}

class _InsetRowState extends State<InsetRow> {
  bool _pressionado = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (v) HapticFeedback.selectionClick();
    setState(() => _pressionado = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final tocavel = widget.onTap != null;

    return GestureDetector(
      onTapDown: tocavel ? (_) => _set(true) : null,
      onTapUp: tocavel ? (_) => _set(false) : null,
      onTapCancel: tocavel ? () => _set(false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Motion.instant,
        // Realce no toque em vez de respingo: mais discreto e mais barato.
        color: _pressionado ? p.surfaceSunken : p.surface,
        padding: widget.padding,
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: Space.md),
            ] else if (widget.icon != null) ...[
              // Quadradinho colorido com o ícone em branco — o desenho dos
              // Ajustes do iPhone. Sem cor definida, o cinza do sistema.
              Container(
                width: InsetRow.iconTile,
                height: InsetRow.iconTile,
                decoration: BoxDecoration(
                  color: widget.tint ?? p.textMuted,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(widget.icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: Space.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      // Uma linha só: subtítulo que quebra deixa as linhas
                      // com alturas diferentes e a lista fica desalinhada.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.value != null) ...[
              const SizedBox(width: Space.sm),
              Text(
                widget.value!,
                style: t.labelLarge?.copyWith(color: p.textSecondary),
              ),
            ],
            if (widget.trailing != null) ...[
              const SizedBox(width: Space.sm),
              widget.trailing!,
            ],
            if (tocavel && widget.showChevron) ...[
              const SizedBox(width: Space.xs),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 15,
                color: p.borderStrong,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
