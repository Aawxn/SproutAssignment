import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/audio_service.dart';
import '../../theme/sprout_theme.dart';

/// Bud's emotional states — drives body wobble, eye shape, arm position
enum BudState { idle, happy, thinking, celebrating, encouraging }

/// "Bud" — the Sprout mascot.
///
/// A round green sprout creature with:
///   - Two leaf-arms that wave on reaction
///   - Dot eyes that blink on a loop
///   - A smile that widens/narrows by state
///   - Body squash-and-stretch on reactions
///
/// Wrapped in [RepaintBoundary] since it animates independently.
/// Uses multiple [AnimationController]s: blink, body, arms.
///
/// Performance: CustomPainter with correct shouldRepaint,
/// no rebuild of parent widget tree during animation.
class BudMascot extends StatefulWidget {
  const BudMascot({
    super.key,
    this.state = BudState.idle,
    this.size = 120.0,
  });

  final BudState state;
  final double size;

  @override
  State<BudMascot> createState() => _BudMascotState();
}

class _BudMascotState extends State<BudMascot>
    with TickerProviderStateMixin {
  // Blink controller — loops every 2–4 seconds
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  // Body reaction controller — squash/stretch on state change
  late final AnimationController _bodyCtrl;
  late final Animation<double> _bodyScaleX;
  late final Animation<double> _bodyScaleY;

  // Arm wave controller — loops when celebrating
  late final AnimationController _armCtrl;
  late final Animation<double> _armAnim;

  // Wobble controller — wiggles on encouraging state
  late final AnimationController _wobbleCtrl;
  late final Animation<double> _wobbleAnim;

  // Idle chirp timer
  late final Ticker _chirpTicker;
  double _chirpAccumulator = 0;
  static const _chirpInterval = 10.0; // seconds

  @override
  void initState() {
    super.initState();

    // ── Blink ─────────────────────────────────────────────────
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
    _scheduleBlink();

    // ── Body reaction ─────────────────────────────────────────
    _bodyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Squash → overshoot → settle (anticipation + payoff)
    _bodyScaleX = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.15), weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 0.92), weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 0.92, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeOut));

    _bodyScaleY = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.88), weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 0.88, end: 1.1), weight: 25),
      TweenSequenceItem(
          tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeOut));

    // ── Arm wave ─────────────────────────────────────────────
    _armCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _armAnim = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _armCtrl, curve: Curves.easeInOut),
    );

    // ── Wobble ───────────────────────────────────────────────
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wobbleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.08), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeOut));

    // Idle chirp ticker
    _chirpTicker = createTicker(_onTick);
    _chirpTicker.start();
  }

  void _onTick(Duration elapsed) {
    final secs = elapsed.inMilliseconds / 1000.0;
    if (secs - _chirpAccumulator >= _chirpInterval) {
      _chirpAccumulator = secs;
      if (widget.state == BudState.idle) {
        AudioService.instance.playBudChirp();
      }
    }
  }

  /// Stagger next blink randomly between 2–4 seconds
  void _scheduleBlink() {
    final delay = Duration(
      milliseconds: 2000 + math.Random().nextInt(2000),
    );
    Future.delayed(delay, () {
      if (!mounted) return;
      _blinkCtrl.forward().then((_) {
        if (!mounted) return;
        _blinkCtrl.reverse().then((_) => _scheduleBlink());
      });
    });
  }

  @override
  void didUpdateWidget(BudMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _reactToStateChange(widget.state);
    }
  }

  void _reactToStateChange(BudState newState) {
    _bodyCtrl.forward(from: 0);

    switch (newState) {
      case BudState.celebrating:
        _armCtrl.repeat(reverse: true);
      case BudState.encouraging:
        _wobbleCtrl.forward(from: 0);
        _armCtrl.stop();
      case BudState.happy:
        _armCtrl.forward(from: 0).then((_) => _armCtrl.reverse());
      case BudState.idle:
      case BudState.thinking:
        _armCtrl.stop();
        _armCtrl.animateTo(0);
    }
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _bodyCtrl.dispose();
    _armCtrl.dispose();
    _wobbleCtrl.dispose();
    _chirpTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _blinkAnim,
          _bodyScaleX,
          _bodyScaleY,
          _armAnim,
          _wobbleAnim,
        ]),
        builder: (context, _) {
          return Transform.rotate(
            angle: _wobbleAnim.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(
                _bodyScaleX.value,
                _bodyScaleY.value,
                1.0,
              ),
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _BudPainter(
                  state: widget.state,
                  blinkValue: _blinkAnim.value,
                  armAngle: _armAnim.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BudPainter extends CustomPainter {
  const _BudPainter({
    required this.state,
    required this.blinkValue,
    required this.armAngle,
  });

  final BudState state;
  final double blinkValue;
  final double armAngle;

  // Cached Paint objects (performance: never recreate in paint())
  static final _bodyPaint = Paint()..color = kSproutGreen;
  static final _bodyHighlightPaint = Paint()..color = kSproutGreenLight;
  static final _leafPaint = Paint()..color = kSproutGreenDark;
  static final _eyePaint = Paint()..color = Colors.white;
  static final _pupilPaint = Paint()..color = const Color(0xFF2D2D2D);
  static final _smilePaint = Paint()
    ..color = const Color(0xFF2D2D2D)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final _cheekPaint = Paint()
    ..color = kCoralPink.withValues(alpha: 0.4);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    _drawArms(canvas, cx, cy, r);
    _drawBody(canvas, cx, cy, r);
    _drawFace(canvas, cx, cy, r);
    _drawLeafTop(canvas, cx, cy, r);
  }

  void _drawArms(Canvas canvas, double cx, double cy, double r) {
    // Left arm (leaf shape)
    canvas.save();
    canvas.translate(cx - r * 0.9, cy + r * 0.1);
    canvas.rotate(-0.4 + armAngle);
    final leftLeaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(-r * 0.5, -r * 0.3, -r * 0.6, r * 0.2, 0, r * 0.35)
      ..cubicTo(r * 0.1, r * 0.1, r * 0.05, -r * 0.1, 0, 0);
    canvas.drawPath(leftLeaf, _leafPaint);
    canvas.restore();

    // Right arm (leaf shape, mirrored)
    canvas.save();
    canvas.translate(cx + r * 0.9, cy + r * 0.1);
    canvas.rotate(0.4 - armAngle);
    final rightLeaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(r * 0.5, -r * 0.3, r * 0.6, r * 0.2, 0, r * 0.35)
      ..cubicTo(-r * 0.1, r * 0.1, -r * 0.05, -r * 0.1, 0, 0);
    canvas.drawPath(rightLeaf, _leafPaint);
    canvas.restore();
  }

  void _drawBody(Canvas canvas, double cx, double cy, double r) {
    // Main body circle
    canvas.drawCircle(Offset(cx, cy), r, _bodyPaint);

    // Highlight (top-left shine)
    canvas.drawCircle(
      Offset(cx - r * 0.25, cy - r * 0.25),
      r * 0.18,
      _bodyHighlightPaint,
    );
  }

  void _drawFace(Canvas canvas, double cx, double cy, double r) {
    final eyeY = cy - r * 0.12;
    final eyeSpacing = r * 0.32;
    final eyeRadius = r * 0.14;

    // Cheeks
    canvas.drawCircle(
      Offset(cx - eyeSpacing * 0.9, eyeY + r * 0.28),
      r * 0.13,
      _cheekPaint,
    );
    canvas.drawCircle(
      Offset(cx + eyeSpacing * 0.9, eyeY + r * 0.28),
      r * 0.13,
      _cheekPaint,
    );

    // Eyes (white circles, then pupils with blink scale)
    for (final dx in [-eyeSpacing, eyeSpacing]) {
      canvas.drawCircle(Offset(cx + dx, eyeY), eyeRadius, _eyePaint);

      // Blink: scale the pupil vertically (blinkValue 1.0=open, 0.05=closed)
      canvas.save();
      canvas.translate(cx + dx, eyeY);
      canvas.scale(1.0, blinkValue);
      canvas.drawCircle(Offset.zero, eyeRadius * 0.55, _pupilPaint);
      // Tiny white shine dot
      canvas.drawCircle(
        Offset(eyeRadius * 0.15, -eyeRadius * 0.15),
        eyeRadius * 0.2,
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }

    // Smile — shape changes by state
    _drawSmile(canvas, cx, cy, r);
  }

  void _drawSmile(Canvas canvas, double cx, double cy, double r) {
    final smileY = cy + r * 0.22;
    final smileW = r * 0.45;

    double curveHeight;
    switch (state) {
      case BudState.celebrating:
        curveHeight = r * 0.28; // BIG smile
      case BudState.happy:
        curveHeight = r * 0.22;
      case BudState.encouraging:
        curveHeight = r * 0.18;
      case BudState.thinking:
        curveHeight = r * 0.08; // Slight smile, "thinking"
      case BudState.idle:
        curveHeight = r * 0.15;
    }

    final path = Path()
      ..moveTo(cx - smileW, smileY - curveHeight * 0.3)
      ..quadraticBezierTo(
        cx,
        smileY + curveHeight,
        cx + smileW,
        smileY - curveHeight * 0.3,
      );
    canvas.drawPath(path, _smilePaint);
  }

  void _drawLeafTop(Canvas canvas, double cx, double cy, double r) {
    // Little leaf/sprout on top of Bud's head
    final leafPaint = Paint()..color = kSproutGreenDark;
    final stemPath = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx, cy - r * 1.3);
    canvas.drawPath(
      stemPath,
      leafPaint..style = PaintingStyle.stroke..strokeWidth = 3,
    );

    final leafPath = Path()
      ..moveTo(cx, cy - r * 1.18)
      ..cubicTo(
        cx + r * 0.22, cy - r * 1.5,
        cx + r * 0.35, cy - r * 1.1,
        cx, cy - r * 1.05,
      );
    canvas.drawPath(leafPath, leafPaint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_BudPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.armAngle != armAngle;
  }
}
