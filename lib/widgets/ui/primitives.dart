import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

/// Rótulo de seção em caixa alta e pequeno.
///
/// Estrutura a página sem competir com o conteúdo — o oposto de título grande
/// e colorido a cada bloco, que era o que deixava a tela agitada.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Superfície padrão: um retângulo de conteúdo com borda discreta.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.radius = Radii.lg,
    this.color,
    this.border = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: p.border) : null,
      ),
      child: child,
    );
  }
}

/// Número grande com rótulo pequeno — o dado como protagonista.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.suffix,
    this.accent = false,
    this.align = CrossAxisAlignment.start,
  });

  final String value;
  final String label;
  final String? suffix;
  final bool accent;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: t.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: accent ? p.accent : p.textPrimary,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 3),
              Text(suffix!, style: t.bodySmall),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: t.bodySmall, maxLines: 2),
      ],
    );
  }
}

/// Etiqueta compacta de metadado (duração, passos, sequência).
class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cor = tone ?? p.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 5),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cor),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Barra de progresso fina com cantos arredondados nas duas pontas.
class ProgressBarThin extends StatelessWidget {
  const ProgressBarThin({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.track,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: track ?? p.surfaceSunken,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? p.accent),
        ),
      ),
    );
  }
}
