import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

enum PressableTone { primary, neutral, ghost, danger }

/// Botão no jeito do iOS: chapado, e responde ao toque apagando um pouco.
///
/// A versão anterior tinha um degrau sólido embaixo que "afundava" e voltava
/// com mola — divertido, mas é a linguagem de fliperama. No iOS o botão não
/// tem profundidade: sob o dedo ele fica mais claro e encolhe de leve, e
/// solta sem ultrapassar.
///
/// **60 fps**: só opacidade e escala mudam por quadro; o conteúdo entra como
/// `child` do AnimatedBuilder e é construído uma vez.
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
    this.expand = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final PressableTone tone;
  final EdgeInsets padding;
  final double radius;
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
    reverseDuration: Motion.base,
  );

  late final Animation<double> _escala = _c.drive(
    Tween(begin: 1.0, end: 0.98).chain(CurveTween(curve: Curves.easeOut)),
  );

  late final Animation<double> _opacidade = _c.drive(
    Tween(begin: 1.0, end: 0.65).chain(CurveTween(curve: Curves.easeOut)),
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
    final (face, onFace) = _cores(p);

    final conteudo = Container(
      width: widget.expand ? double.infinity : null,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(widget.radius),
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
        // Desligado no iOS é esmaecido, não cinza: a cor continua dizendo o
        // que o botão faz.
        opacity: _ativo ? 1 : 0.35,
        child: GestureDetector(
          onTapDown: _descer,
          onTapUp: _subir,
          onTapCancel: _subir,
          onTap: _ativo ? widget.onPressed : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _c,
            child: conteudo,
            builder: (context, child) => Opacity(
              opacity: _opacidade.value,
              child: Transform.scale(scale: _escala.value, child: child),
            ),
          ),
        ),
      ),
    );
  }

  /// Os estilos de botão do iOS: preenchido, cinza com texto azul, só texto,
  /// e destrutivo.
  (Color face, Color onFace) _cores(Palette p) {
    switch (widget.tone) {
      case PressableTone.primary:
        return (p.accent, p.onAccent);
      case PressableTone.neutral:
        return (p.surfaceSunken, p.accent);
      case PressableTone.ghost:
        return (Colors.transparent, p.accent);
      case PressableTone.danger:
        return (p.danger, Colors.white);
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
    Tween(begin: 1.0, end: 0.98).chain(CurveTween(curve: Curves.easeOut)),
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
              // Sem contorno em repouso (o cartão se separa do fundo pela
              // cor); o azul aparece só no escolhido.
              border: Border.all(
                color: sel ? p.accent : Colors.transparent,
                width: 1.5,
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
