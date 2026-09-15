import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

enum PressableTone { primary, neutral, ghost, danger }

/// Botão com a resposta de toque da Apple.
///
/// Dois movimentos ao mesmo tempo, que é o que dá a sensação física:
///
/// 1. **Encolhe sob o dedo** (escala 1 → 0,96). É o gesto característico do
///    iOS — o botão responde onde o dedo está, mesmo quando o dedo o cobre.
/// 2. **Afunda** na base sólida, sumindo com o degrau.
///
/// Ao soltar, volta com leve ultrapassagem (`easeOutBack`), como mola. Descer
/// é mais rápido que subir: reagir tem de ser instantâneo, voltar pode
/// respirar.
///
/// **60 fps**: só as matrizes de Transform refazem por quadro. O conteúdo
/// entra como `child` do AnimatedBuilder e é construído uma vez; Transform é
/// pintura, não layout, então nada é remedido durante a animação.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.tone = PressableTone.primary,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Space.lg,
      vertical: Space.lg,
    ),
    this.radius = Radii.button,
    this.depth = Depth.press,
    this.expand = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final PressableTone tone;
  final EdgeInsets padding;
  final double radius;
  final double depth;
  final bool expand;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.instant,
    reverseDuration: Motion.fast,
  );

  late final Animation<double> _escala = _c.drive(
    Tween(begin: 1.0, end: 0.96).chain(CurveTween(curve: Motion.press)),
  );

  bool get _ativo => widget.enabled && widget.onPressed != null;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _descer(_) {
    if (!_ativo) return;
    _c.forward();
    // Retorno tátil no toque, não na soltura: é quando a pessoa espera sentir.
    HapticFeedback.lightImpact();
  }

  void _subir([_]) {
    if (_c.value > 0) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (face, base, onFace) = _cores(p);
    final depth = widget.depth;

    final conteudo = Container(
      width: widget.expand ? double.infinity : null,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.tone == PressableTone.ghost
            ? Border.all(color: p.border)
            : null,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: onFace,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: onFace, size: 19),
          child: Center(
            widthFactor: widget.expand ? null : 1,
            child: widget.child,
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: Opacity(
        opacity: _ativo ? 1 : 0.4,
        child: GestureDetector(
          onTapDown: _descer,
          onTapUp: _subir,
          onTapCancel: _subir,
          onTap: _ativo ? widget.onPressed : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _c,
            // Construído uma vez; o quadro só recalcula as transformações.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: depth,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(widget.radius),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: depth),
                  child: conteudo,
                ),
              ],
            ),
            builder: (context, child) => Transform.scale(
              scale: _escala.value,
              child: Transform.translate(
                offset: Offset(0, depth * _c.value),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color face, Color base, Color onFace) _cores(Palette p) {
    switch (widget.tone) {
      case PressableTone.primary:
        return (p.accent, p.accentShadow, p.onAccent);
      case PressableTone.neutral:
        return (p.surfaceRaised, p.border, p.textPrimary);
      case PressableTone.ghost:
        return (p.surface, p.border, p.textPrimary);
      case PressableTone.danger:
        return (p.danger, const Color(0xFF9B3232), Colors.white);
    }
  }
}

/// Cartão tocável: encolhe sob o dedo, sem o degrau do botão.
///
/// Item de lista não precisa parecer botão — precisa responder ao toque.
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(Space.lg),
    this.radius = Radii.card,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets padding;
  final double radius;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.instant,
    reverseDuration: Motion.fast,
  );

  late final Animation<double> _escala = _c.drive(
    Tween(begin: 1.0, end: 0.975).chain(CurveTween(curve: Motion.press)),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _descer(_) {
    if (widget.onTap == null) return;
    _c.forward();
    HapticFeedback.selectionClick();
  }

  void _subir([_]) {
    if (_c.value > 0) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sel = widget.selected;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _descer,
        onTapUp: _subir,
        onTapCancel: _subir,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _c,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: sel ? p.accentSoft : p.surface,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: sel ? p.accent : p.border,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: widget.child,
          ),
          builder: (context, child) =>
              Transform.scale(scale: _escala.value, child: child),
        ),
      ),
    );
  }
}
