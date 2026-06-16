import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/sprout_theme.dart';
import '../../widgets/mascot/bud_mascot.dart';
import '../../widgets/common/sprout_button.dart';
import '../../widgets/reward/celebration_overlay.dart';

// ─────────────────────────────────────────────────────────────
//  Shape data
// ─────────────────────────────────────────────────────────────
enum _ShapeType { circle, square, triangle, star, heart }

const _shapeLabels = {
  _ShapeType.circle: 'Circle',
  _ShapeType.square: 'Square',
  _ShapeType.triangle: 'Triangle',
  _ShapeType.star: 'Star',
  _ShapeType.heart: 'Heart',
};



// ─────────────────────────────────────────────────────────────
//  Shape Match Screen
// ─────────────────────────────────────────────────────────────

/// Activity 1: Shape Matching
/// Child taps the shape that matches the prompt at the top.
///
/// Design choices for 3–5 year olds:
///   - Large shape tiles (min 100dp) — accommodates imprecise motor control
///   - Shapes drawn with CustomPainter (no image assets needed)
///   - Wrong tap: tile wobbles + "try again" bubble, never silence
///   - 4 rounds per session, then celebration
class ShapeMatchScreen extends StatefulWidget {
  const ShapeMatchScreen({super.key});

  @override
  State<ShapeMatchScreen> createState() => _ShapeMatchScreenState();
}

class _ShapeMatchScreenState extends State<ShapeMatchScreen>
    with TickerProviderStateMixin {
  final _rng = math.Random();
  late List<_ShapeType> _options;
  late _ShapeType _target;
  BudState _budState = BudState.idle;
  bool _showTryAgain = false;
  bool _showCelebration = false;
  int _round = 0;
  static const _totalRounds = 4;

  // Per-tile wobble controllers
  final Map<_ShapeType, AnimationController> _wobbleCtrs = {};
  final Map<_ShapeType, Animation<double>> _wobbleAnims = {};

  @override
  void initState() {
    super.initState();
    // analytics.logEvent('activity_started', {'activity': 'shape_match'});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().startActivity();
      _generateRound();
      AudioService.instance.speak('Can you find the shape?');
    });
  }

  void _generateRound() {
    final allShapes = _ShapeType.values.toList()..shuffle(_rng);
    _target = allShapes.first;
    _options = allShapes.take(4).toList()..shuffle(_rng);

    // Create wobble controllers for each tile
    for (final shape in _options) {
      _wobbleCtrs[shape]?.dispose();
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _wobbleCtrs[shape] = ctrl;
      _wobbleAnims[shape] = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.12), weight: 25),
        TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 25),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }

    setState(() {
      _budState = BudState.thinking;
      _showTryAgain = false;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _budState = BudState.idle);
    });

    AudioService.instance.speak(
      'Find the ${_shapeLabels[_target]}!',
    );
  }

  void _onShapeTapped(_ShapeType tapped) async {
    // analytics.logEvent('item_tapped', {'correct': tapped == _target, 'attempt': context.read<ActivityProvider>().attempts + 1});
    await AudioService.instance.playTapAck();

    if (tapped == _target) {
      _onCorrect();
    } else {
      _onWrong(tapped);
    }
  }

  void _onCorrect() async {
    final provider = context.read<ActivityProvider>();
    provider.recordCorrect();
    setState(() => _budState = BudState.happy);
    await AudioService.instance.playCorrect();
    await AudioService.instance.speak('Yes! That\'s the ${_shapeLabels[_target]}!');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _round++;

    if (_round >= _totalRounds) {
      // analytics.logEvent('activity_completed', {'duration_seconds': provider.elapsedSeconds, 'score': provider.score});
      // analytics.logEvent('reward_shown', {'activity': 'shape_match'});
      provider.completeActivity('shapes');
      await AudioService.instance.playCelebrate();
      if (!mounted) return;
      setState(() {
        _budState = BudState.celebrating;
        _showCelebration = true;
      });
    } else {
      _generateRound();
    }
  }

  void _onWrong(_ShapeType tapped) async {
    final provider = context.read<ActivityProvider>();
    provider.recordIncorrect();
    _wobbleCtrs[tapped]?.forward(from: 0);
    await AudioService.instance.playTryAgain();

    if (!mounted) return;
    setState(() {
      _budState = BudState.encouraging;
      _showTryAgain = true;
    });

    // After 2 wrong attempts on this round, Bud gives a visual hint
    if (provider.attempts > 0 && provider.attempts % 2 == 0) {
      await AudioService.instance.speak(
        'It\'s the ${_shapeLabels[_target]}! Look for it!',
      );
    } else {
      await AudioService.instance.speak('Hmm, try again!');
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _showTryAgain = false);
  }

  void _restart() {
    _round = 0;
    setState(() => _showCelebration = false);
    context.read<ActivityProvider>().startActivity();
    _generateRound();
  }

  @override
  void dispose() {
    for (final ctrl in _wobbleCtrs.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWarmCream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Consumer<ActivityProvider>(
                  builder: (_, p, __) => ActivityHeader(
                    accentColor: kShapeColor,
                    scoreLabel: '⭐ ${p.score}',
                  ),
                ),
                const SizedBox(height: kSpacingM),
                _buildBudAndPrompt(),
                const SizedBox(height: kSpacingL),
                _buildShapeGrid(),
                if (_showTryAgain) ...[
                  const SizedBox(height: kSpacingM),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: kSpacingL),
                    child: TryAgainBubble(),
                  ),
                ],
                const Spacer(),
                ProgressDots(
                  total: _totalRounds,
                  completed: _round,
                  color: kShapeColor,
                ),
                const SizedBox(height: kSpacingL),
              ],
            ),
            if (_showCelebration)
              Positioned.fill(
                child: CelebrationOverlay(
                  message: 'You found all the shapes! 🎉',
                  onDismiss: _restart,
                ),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildBudAndPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BudMascot(state: _budState, size: 90),
          const SizedBox(height: kSpacingM),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: kSpacingS),
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingM,
              vertical: kSpacingM,
            ),
            decoration: BoxDecoration(
              color: kShapeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: kShapeColor.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Find the ', style: kBodyStyle),
                CustomPaint(
                  size: const Size(36, 36),
                  painter: _ShapePainter(shape: _target, color: kShapeColor),
                ),
                const SizedBox(width: kSpacingS),
                Flexible(
                  child: Text(
                    _shapeLabels[_target]!,
                    style: kActivityPromptStyle.copyWith(color: kShapeColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: kSpacingM,
        crossAxisSpacing: kSpacingM,
        children: _options.map((shape) => _buildShapeTile(shape)).toList(),
      ),
    );
  }

  Widget _buildShapeTile(_ShapeType shape) {
    final wobble = _wobbleAnims[shape];
    return AnimatedBuilder(
      animation: wobble ?? kAlwaysDismissedAnimation,
      builder: (context, _) => Transform.rotate(
        angle: wobble?.value ?? 0.0,
        child: GestureDetector(
          onTap: () => _onShapeTapped(shape),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kCardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _ShapePainter(
                    shape: shape,
                    color: _shapeColor(shape),
                  ),
                ),
                const SizedBox(height: kSpacingS),
                Text(
                  _shapeLabels[shape]!,
                  style: kBodyStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _shapeColor(_ShapeType shape) {
    const colors = {
      _ShapeType.circle: kSkyBlue,
      _ShapeType.square: kSproutGreen,
      _ShapeType.triangle: kCoralPink,
      _ShapeType.star: kSunshineYellow,
      _ShapeType.heart: kCoralPink,
    };
    return colors[shape] ?? kSproutGreen;
  }
}

// ─────────────────────────────────────────────────────────────
//  Shape CustomPainter
// ─────────────────────────────────────────────────────────────
class _ShapePainter extends CustomPainter {
  const _ShapePainter({required this.shape, required this.color});

  final _ShapeType shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.4;

    switch (shape) {
      case _ShapeType.circle:
        canvas.drawCircle(Offset(cx, cy), r, paint);

      case _ShapeType.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: r * 1.8,
              height: r * 1.8,
            ),
            const Radius.circular(8),
          ),
          paint,
        );

      case _ShapeType.triangle:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r)
          ..lineTo(cx - r, cy + r)
          ..close();
        canvas.drawPath(path, paint);

      case _ShapeType.star:
        _drawStar(canvas, cx, cy, r, paint);

      case _ShapeType.heart:
        _drawHeart(canvas, cx, cy, r, paint);
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = (i * 2 * math.pi / 5) - math.pi / 2;
      final inner = outer + math.pi / 5;
      if (i == 0) {
        path.moveTo(cx + math.cos(outer) * r, cy + math.sin(outer) * r);
      } else {
        path.lineTo(cx + math.cos(outer) * r, cy + math.sin(outer) * r);
      }
      path.lineTo(
        cx + math.cos(inner) * r * 0.4,
        cy + math.sin(inner) * r * 0.4,
      );
    }
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double r, Paint p) {
    final path = Path()
      ..moveTo(cx, cy + r * 0.6)
      ..cubicTo(cx - r * 1.5, cy - r * 0.3, cx - r * 1.5, cy - r, cx, cy - r * 0.3)
      ..cubicTo(cx + r * 1.5, cy - r, cx + r * 1.5, cy - r * 0.3, cx, cy + r * 0.6);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.color != color;
}
