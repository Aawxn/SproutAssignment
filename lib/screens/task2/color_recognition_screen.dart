import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/sprout_theme.dart';
import '../../widgets/mascot/bud_mascot.dart';
import '../../widgets/common/sprout_button.dart';
import '../../widgets/reward/celebration_overlay.dart';

/// Activity 3: Color Recognition
///
/// Bud holds a colored flag balloon. Child taps the matching
/// colored circle from 4 large options.
///
/// Design choices:
///   - Color circles are 110dp (generous for toddlers)
///   - Colors named verbally via TTS ("Can you find RED?")
///   - Wrong tap: the circle shakes, correct color highlighted
///   - 5 colors taught across 4 rounds
class ColorRecognitionScreen extends StatefulWidget {
  const ColorRecognitionScreen({super.key});

  @override
  State<ColorRecognitionScreen> createState() => _ColorRecognitionScreenState();
}

class _ColorRecognitionScreenState extends State<ColorRecognitionScreen>
    with TickerProviderStateMixin {
  static const _colorData = [
    _ColorEntry('Red', kCoralPink, '🔴'),
    _ColorEntry('Blue', kSkyBlue, '🔵'),
    _ColorEntry('Green', kSproutGreen, '🟢'),
    _ColorEntry('Yellow', kSunshineYellow, '🟡'),
    _ColorEntry('Purple', kSoftPurple, '🟣'),
    _ColorEntry('Orange', kOrange, '🟠'),
  ];

  final _rng = math.Random();
  late _ColorEntry _target;
  late List<_ColorEntry> _options;

  BudState _budState = BudState.idle;
  bool _showTryAgain = false;
  bool _showCelebration = false;
  int _round = 0;
  static const _totalRounds = 4;

  // Shake animation for wrong tap
  final Map<String, AnimationController> _shakeCtrs = {};
  final Map<String, Animation<double>> _shakeAnims = {};

  @override
  void initState() {
    super.initState();
    // analytics.logEvent('activity_started', {'activity': 'color_recognition'});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().startActivity();
      _generateRound();
    });
  }

  void _generateRound() {
    final shuffled = List.of(_colorData)..shuffle(_rng);
    _target = shuffled.first;
    _options = shuffled.take(4).toList()..shuffle(_rng);

    // Create shake controllers
    for (final c in _options) {
      _shakeCtrs[c.name]?.dispose();
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
      _shakeCtrs[c.name] = ctrl;
      _shakeAnims[c.name] = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 12.0, end: -6.0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 20),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }

    setState(() {
      _budState = BudState.idle;
      _showTryAgain = false;
    });

    AudioService.instance.speak('Can you find ${_target.name}?');
  }

  void _onColorTapped(_ColorEntry color) async {
    // analytics.logEvent('item_tapped', {'correct': color.name == _target.name, 'attempt': context.read<ActivityProvider>().attempts + 1});
    await AudioService.instance.playTapAck();

    if (color.name == _target.name) {
      _onCorrect();
    } else {
      _onWrong(color);
    }
  }

  void _onCorrect() async {
    final provider = context.read<ActivityProvider>();
    provider.recordCorrect();
    setState(() => _budState = BudState.happy);
    await AudioService.instance.playCorrect();
    await AudioService.instance.speak('Yes! That\'s ${_target.name}! ${_target.emoji}');

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _round++;

    if (_round >= _totalRounds) {
      // analytics.logEvent('activity_completed', {'duration_seconds': provider.elapsedSeconds});
      // analytics.logEvent('reward_shown', {'activity': 'color_recognition'});
      provider.completeActivity('colors');
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

  void _onWrong(_ColorEntry color) async {
    context.read<ActivityProvider>().recordIncorrect();
    _shakeCtrs[color.name]?.forward(from: 0);
    await AudioService.instance.playTryAgain();
    setState(() {
      _budState = BudState.encouraging;
      _showTryAgain = true;
    });
    await AudioService.instance.speak('That\'s ${color.name}. Try again!');
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
    for (final ctrl in _shakeCtrs.values) {
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
                    accentColor: kColorColor,
                    scoreLabel: '⭐ ${p.score}',
                  ),
                ),
                const SizedBox(height: kSpacingM),
                _buildBudWithBalloon(),
                const SizedBox(height: kSpacingL),
                _buildColorGrid(),
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
                  color: kColorColor,
                ),
                const SizedBox(height: kSpacingL),
              ],
            ),
            if (_showCelebration)
              Positioned.fill(
                child: CelebrationOverlay(
                  message: 'You know all the colors! 🎨',
                  onDismiss: _restart,
                ),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildBudWithBalloon() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Balloon (the color prompt)
            _BalloonWidget(color: _target.color),
            const SizedBox(width: kSpacingM),
            BudMascot(state: _budState, size: 100),
          ],
        ),
        const SizedBox(height: kSpacingM),
        Text(
          'Find ${_target.name}!',
          style: kActivityPromptStyle.copyWith(color: _target.color),
        ),
      ],
    );
  }

  Widget _buildColorGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingXL),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: kSpacingL,
        crossAxisSpacing: kSpacingL,
        children: _options.map((c) => _buildColorTile(c)).toList(),
      ),
    );
  }

  Widget _buildColorTile(_ColorEntry color) {
    final shake = _shakeAnims[color.name];
    return AnimatedBuilder(
      animation: shake ?? kAlwaysDismissedAnimation,
      builder: (context, _) => Transform.translate(
        offset: Offset(shake?.value ?? 0, 0),
        child: GestureDetector(
          onTap: () => _onColorTapped(color),
          child: Container(
            decoration: BoxDecoration(
              color: color.color,
              borderRadius: BorderRadius.circular(kCardRadius * 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(color.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: kSpacingS),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    color.name,
                    style: kBodyStyle.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}

/// Animated balloon widget to show the target color
class _BalloonWidget extends StatefulWidget {
  const _BalloonWidget({required this.color});
  final Color color;

  @override
  State<_BalloonWidget> createState() => _BalloonWidgetState();
}

class _BalloonWidgetState extends State<_BalloonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _floatAnim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: CustomPaint(
            size: const Size(70, 90),
            painter: _BalloonPainter(color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  const _BalloonPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;

    // Balloon body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.42),
        width: size.width * 0.85,
        height: size.height * 0.72,
      ),
      paint,
    );

    // Highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.15, size.height * 0.28),
        width: size.width * 0.2,
        height: size.height * 0.15,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Knot
    canvas.drawCircle(
      Offset(cx, size.height * 0.79),
      4,
      Paint()..color = color.withValues(alpha: 0.8),
    );

    // String
    final stringPath = Path()
      ..moveTo(cx, size.height * 0.83)
      ..quadraticBezierTo(
        cx + 6,
        size.height * 0.91,
        cx,
        size.height,
      );
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = Colors.brown.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BalloonPainter old) => old.color != color;
}

class _ColorEntry {
  const _ColorEntry(this.name, this.color, this.emoji);
  final String name;
  final Color color;
  final String emoji;
}
