import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

/// Régua de duração que se define arrastando.
///
/// Substitui o slider porque arrastar uma régua é mais preciso e mais gostoso
/// de usar: o dedo percorre distância proporcional ao tempo, e cada passo dá
/// um toque tátil. Soltar com velocidade deixa a régua correr e desacelerar
/// como objeto físico.
///
/// **60 fps**: um `CustomPainter` desenha os traços e só repinta quando a
/// posição muda — sem widget por traço, sem layout durante o arrasto. O
/// `shouldRepaint` compara apenas o que muda.
class DurationDial extends StatefulWidget {
  const DurationDial({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.min = 5,
    this.max = 180,
    this.step = 5,
  });

  final int minutes;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  State<DurationDial> createState() => _DurationDialState();
}

class _DurationDialState extends State<DurationDial>
    with SingleTickerProviderStateMixin {
  /// Pixels por minuto. Calibrado para 1 h ocupar pouco mais que a tela.
  static const double _px = 4.2;

  late double _pos = widget.minutes * _px;
  late final AnimationController _inercia = AnimationController.unbounded(
    vsync: this,
  )..addListener(_aoDeslizar);

  int _ultimoValor = 0;

  @override
  void initState() {
    super.initState();
    _ultimoValor = widget.minutes;
  }

  @override
  void didUpdateWidget(DurationDial old) {
    super.didUpdateWidget(old);
    // Mudança vinda de fora (um atalho tocado) reposiciona a régua.
    if (widget.minutes != _ultimoValor && !_inercia.isAnimating) {
      _ultimoValor = widget.minutes;
      setState(() => _pos = widget.minutes * _px);
    }
  }

  @override
  void dispose() {
    _inercia.dispose();
    super.dispose();
  }

  double get _minPos => widget.min * _px;
  double get _maxPos => widget.max * _px;

  int get _valorAtual {
    final bruto = _pos / _px;
    final passo = widget.step;
    return ((bruto / passo).round() * passo).clamp(widget.min, widget.max);
  }

  void _atualizar(double nova, {bool tatil = true}) {
    final limitada = nova.clamp(_minPos, _maxPos);
    if (limitada == _pos) return;
    setState(() => _pos = limitada);

    final valor = _valorAtual;
    if (valor != _ultimoValor) {
      _ultimoValor = valor;
      // Um toque por passo: é o que dá a sensação de encaixe.
      if (tatil) HapticFeedback.selectionClick();
      widget.onChanged(valor);
    }
  }

  void _aoDeslizar() => _atualizar(_inercia.value);

  void _iniciar(DragStartDetails _) => _inercia.stop();

  void _arrastar(DragUpdateDetails d) {
    _inercia.stop();
    // Arrastar para a esquerda aumenta: a régua anda sob um indicador fixo.
    _atualizar(_pos - d.delta.dx);
  }

  void _soltar(DragEndDetails d) {
    final v = -d.velocity.pixelsPerSecond.dx;
    if (v.abs() < 60) {
      _encaixar();
      return;
    }
    // Atrito real em vez de parada seca: o arrasto continua e desacelera.
    _inercia.value = _pos;
    _inercia
        .animateWith(FrictionSimulation(0.015, _pos, v))
        .whenComplete(_encaixar);
  }

  /// Ao parar, alinha no passo de 5 min mais próximo.
  void _encaixar() {
    final alvo = (_valorAtual * _px).toDouble();
    if ((alvo - _pos).abs() < 0.5) return;
    _inercia.value = _pos;
    _inercia.animateTo(
      alvo,
      duration: Motion.fast,
      curve: Motion.enter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final valor = _valorAtual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$valor',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(width: Space.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'minutos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Spacer(),
            Icon(Icons.touch_app_outlined, size: 16, color: p.textMuted),
            const SizedBox(width: Space.xs),
            Text('arraste', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: Space.md),
        GestureDetector(
          onHorizontalDragStart: _iniciar,
          onHorizontalDragUpdate: _arrastar,
          onHorizontalDragEnd: _soltar,
          behavior: HitTestBehavior.opaque,
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size(double.infinity, 76),
              painter: _ReguaPainter(
                pos: _pos,
                px: _px,
                min: widget.min,
                max: widget.max,
                tick: p.borderStrong,
                tickForte: p.textMuted,
                rotulo: p.textMuted,
                indicador: p.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReguaPainter extends CustomPainter {
  _ReguaPainter({
    required this.pos,
    required this.px,
    required this.min,
    required this.max,
    required this.tick,
    required this.tickForte,
    required this.rotulo,
    required this.indicador,
  });

  final double pos;
  final double px;
  final int min;
  final int max;
  final Color tick, tickForte, rotulo, indicador;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.width / 2;
    final baseY = size.height - 22;

    final fino = Paint()
      ..color = tick
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final grosso = Paint()
      ..color = tickForte
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Só os traços visíveis entram no laço — desenhar 180 min inteiros a cada
    // quadro seria desperdício.
    final primeiro = math.max(min, ((pos - centro) / px).floor());
    final ultimo = math.min(max, ((pos + centro) / px).ceil());

    for (var m = primeiro; m <= ultimo; m++) {
      if (m % 5 != 0) continue;
      final x = centro + (m * px - pos);
      final marco = m % 15 == 0;
      final altura = marco ? 26.0 : 14.0;

      canvas.drawLine(
        Offset(x, baseY - altura),
        Offset(x, baseY),
        marco ? grosso : fino,
      );

      if (marco) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$m',
            style: TextStyle(
              color: rotulo,
              fontSize: 11,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTheme.tabular,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, baseY + 6));
      }
    }

    // Indicador fixo no centro: é ele que "lê" a régua.
    final agulha = Paint()
      ..color = indicador
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centro, baseY - 34),
      Offset(centro, baseY + 2),
      agulha,
    );
    canvas.drawCircle(Offset(centro, baseY - 38), 4, Paint()..color = indicador);
  }

  @override
  bool shouldRepaint(_ReguaPainter old) =>
      old.pos != pos || old.indicador != indicador || old.tick != tick;
}
