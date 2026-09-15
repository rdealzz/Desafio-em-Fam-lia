import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

enum PressableTone { primary, neutral, ghost, danger }

/// Botão com profundidade real: uma base sólida fica sob a face, e ao tocar a
/// face desce até encostar nela. Some o degrau, o botão parece afundar.
///
/// Por que assim e não relevo com luz falsa dos dois lados (neumorfismo): a
/// referência de 2026 é elevação seletiva, e o relevo simulado envelheceu mal
/// além de destruir o contraste.
///
/// **60 fps**: só o `Transform` reconstrói a cada quadro — o conteúdo entra
/// como `child` do `AnimatedBuilder` e é construído uma vez. Transform é
/// operação de pintura, não de layout, então nada é remedido durante a
/// animação. O `RepaintBoundary` isola o repinte do resto da tela.
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
    this.radius = Radii.md,
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
        style: TextStyle(color: onFace),
        child: IconTheme.merge(
          data: IconThemeData(color: onFace),
          child: Center(
            widthFactor: widget.expand ? null : 1,
            child: widget.child,
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: Opacity(
        opacity: _ativo ? 1 : 0.45,
        child: GestureDetector(
          onTapDown: _descer,
          onTapUp: _subir,
          onTapCancel: _subir,
          onTap: _ativo ? widget.onPressed : null,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Base sólida: o degrau que a face cobre ao ser pressionada.
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
              AnimatedBuilder(
                animation: _c,
                // `child` é construído UMA vez e repassado: o quadro só refaz
                // a matriz do Transform.
                child: Padding(
                  padding: EdgeInsets.only(bottom: depth),
                  child: conteudo,
                ),
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, depth * _c.value),
                  child: child,
                ),
              ),
            ],
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

/// Cartão tocável com o mesmo princípio de profundidade, degrau menor.
///
/// Aqui a profundidade sinaliza "isto é tocável" sem transformar cada item da
/// lista num botão gigante. Selecionado, ganha o acento e perde o degrau —
/// fica visualmente pressionado, que é o que "escolhido" significa.
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(Space.lg),
    this.radius = Radii.lg,
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
  static const double _depth = 3;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.instant,
    reverseDuration: Motion.fast,
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
    final selecionado = widget.selected;

    final face = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: selecionado ? p.accentSoft : p.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: selecionado ? p.accent : p.border,
          width: selecionado ? 1.5 : 1,
        ),
      ),
      child: widget.child,
    );

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _descer,
        onTapUp: _subir,
        onTapCancel: _subir,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: _depth,
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selecionado ? p.accentShadow : p.border,
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _c,
              child: Padding(
                padding: const EdgeInsets.only(bottom: _depth),
                child: face,
              ),
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _depth * _c.value),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
