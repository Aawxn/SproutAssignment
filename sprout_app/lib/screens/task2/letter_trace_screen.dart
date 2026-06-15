import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/sprout_theme.dart';
import '../../widgets/common/sprout_button.dart';
import '../../widgets/mascot/bud_mascot.dart';
import '../../widgets/reward/celebration_overlay.dart';

/// Activity 4: Letter / Number Tracing
///
/// Shows a large letter or number outline as dotted guide points.
/// Child taps dots in sequence — each lights up with a sound.
/// No "wrong" state possible — dots just remain unlit until tapped.
/// Bud celebrates when all dots on a letter are lit.
///
/// Design notes:
///   - Tap-the-dots approach (not drag) — more accessible for toddlers
///   - Dots are 56dp (generous tap target even inside the letter path)
///   - Letter outlines drawn as CustomPainter dot paths
///   - Teaches: A B C 1 2 3 across 6 rounds
class LetterTraceScreen extends StatefulWidget {
  const LetterTraceScreen({super.key});

  @override
  State<LetterTraceScreen> createState() => _LetterTraceScreenState();
}

class _LetterTraceScreenState extends State<LetterTraceScreen>
    with TickerProviderStateMixin {
  static const _sequence = ['A', 'B', 'C', '1', '2', '3'];
  int _letterIndex = 0;
  late List<_TraceDot> _dots;
  int _nextDotIndex = 0;

  BudState _budState = BudState.idle;
  bool _showCelebration = false;
  bool _showHint = false;

  // Pulse animation for next-dot hint
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // analytics.logEvent('activity_started', {'activity': 'letter_tracing'});

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().startActivity();
      _loadLetter();
    });
  }

  void _loadLetter() {
    final letter = _sequence[_letterIndex];
    _dots = _buildDotsFor(letter);
    _nextDotIndex = 0;

    setState(() {
      _budState = BudState.thinking;
      _showHint = false;
    });

    AudioService.instance.speak('Let\'s trace the letter $letter!');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _budState = BudState.idle;
          _showHint = true; // Show pulsing dot hint after delay
        });
      }
    });
  }

  void _onDotTapped(int index) async {
    if (_dots[index].lit) return; // Already tapped

    if (index != _nextDotIndex) {
      // Tapped out of order — guide them gently (no penalty)
      await AudioService.instance.playTapAck();
      await AudioService.instance.speak('Start from dot 1!');
      return;
    }

    // analytics.logEvent('item_tapped', {'correct': true, 'attempt': _nextDotIndex + 1});
    await AudioService.instance.playTapAck();

    setState(() {
      _dots[index].lit = true;
      _nextDotIndex++;
    });

    if (_nextDotIndex == _dots.length) {
      // All dots traced!
      _onLetterComplete();
    } else {
      setState(() => _budState = BudState.happy);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _budState = BudState.idle);
      });
    }
  }

  void _onLetterComplete() async {
    context.read<ActivityProvider>().recordCorrect();
    setState(() => _budState = BudState.celebrating);
    await AudioService.instance.playCorrect();
    await AudioService.instance.speak('You traced ${_sequence[_letterIndex]}! Great job!');

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _letterIndex++;

    if (_letterIndex >= _sequence.length) {
      // analytics.logEvent('activity_completed', {'duration_seconds': context.read<ActivityProvider>().elapsedSeconds});
      // analytics.logEvent('reward_shown', {'activity': 'letter_tracing'});
      context.read<ActivityProvider>().completeActivity();
      await AudioService.instance.playCelebrate();
      setState(() {
        _budState = BudState.celebrating;
        _showCelebration = true;
      });
    } else {
      _loadLetter();
    }
  }

  void _restart() {
    _letterIndex = 0;
    setState(() => _showCelebration = false);
    context.read<ActivityProvider>().startActivity();
    _loadLetter();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letter = _sequence[_letterIndex.clamp(0, _sequence.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFFF0EAF8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ActivityHeader(
                  accentColor: kTraceColor,
                  scoreLabel: '$letter  •  $_nextDotIndex / ${_dots.length}',
                ),
                const SizedBox(height: kSpacingS),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BudMascot(state: _budState, size: 72),
                      const SizedBox(width: kSpacingM),
                      Flexible(
                        child: Text(
                          'Tap the dots to trace $letter!',
                          style: kBodyStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kSpacingM),
                Expanded(child: _buildTraceArea(letter)),
                _buildProgressRow(),
                const SizedBox(height: kSpacingL),
              ],
            ),
            if (_showCelebration)
              Positioned.fill(
                child: CelebrationOverlay(
                  message: 'You traced A B C 1 2 3! 🌟',
                  onDismiss: _restart,
                ),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildTraceArea(String letter) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Ghost letter background (large, faint guide)
            Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: constraints.maxHeight * 0.7,
                  fontWeight: FontWeight.w900,
                  color: kTraceColor.withValues(alpha: 0.07),
                  height: 1,
                ),
              ),
            ),

            // Dots
            ...List.generate(_dots.length, (i) {
              final dot = _dots[i];
              final x = dot.x * constraints.maxWidth;
              final y = dot.y * constraints.maxHeight;
              final isNext = i == _nextDotIndex && _showHint;

              return Positioned(
                left: x - 28,
                top: y - 28,
                child: GestureDetector(
                  onTap: () => _onDotTapped(i),
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: isNext ? _pulseAnim.value : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: dot.lit
                              ? kTraceColor
                              : isNext
                                  ? kTraceColor.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: dot.lit ? kSproutGreenDark : kTraceColor,
                            width: 3,
                          ),
                          boxShadow: dot.lit
                              ? [BoxShadow(color: kTraceColor.withValues(alpha: 0.4), blurRadius: 8)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: dot.lit ? Colors.white : kTraceColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildProgressRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_sequence.length, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: i < _letterIndex
                ? kTraceColor
                : i == _letterIndex
                    ? kTraceColor.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kTraceColor, width: 2),
          ),
          child: Center(
            child: Text(
              _sequence[i],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: i <= _letterIndex ? Colors.white : kTraceColor,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Returns dot positions (normalized 0–1) for each letter/number.
  /// Dots follow the natural stroke order for each character.
  List<_TraceDot> _buildDotsFor(String letter) {
    switch (letter) {
      case 'A':
        return [
          _TraceDot(0.5, 0.08),  // 1: top apex
          _TraceDot(0.72, 0.45), // 2: right middle
          _TraceDot(0.62, 0.68), // 3: right lower
          _TraceDot(0.5, 0.52),  // 4: crossbar center
          _TraceDot(0.38, 0.68), // 5: left lower
          _TraceDot(0.28, 0.45), // 6: left middle
        ];
      case 'B':
        return [
          _TraceDot(0.3, 0.1),   // 1: top left
          _TraceDot(0.3, 0.35),  // 2: middle left
          _TraceDot(0.3, 0.6),   // 3: bottom left
          _TraceDot(0.3, 0.88),  // 4: very bottom
          _TraceDot(0.55, 0.75), // 5: lower bump right
          _TraceDot(0.62, 0.55), // 6: lower bump peak
          _TraceDot(0.55, 0.35), // 7: upper bump right
          _TraceDot(0.62, 0.22), // 8: upper bump peak
        ];
      case 'C':
        return [
          _TraceDot(0.65, 0.15), // 1: top right
          _TraceDot(0.45, 0.1),  // 2: top center
          _TraceDot(0.28, 0.28), // 3: top left
          _TraceDot(0.22, 0.5),  // 4: left middle
          _TraceDot(0.28, 0.72), // 5: bottom left
          _TraceDot(0.45, 0.88), // 6: bottom center
          _TraceDot(0.65, 0.84), // 7: bottom right
        ];
      case '1':
        return [
          _TraceDot(0.4, 0.12),  // 1: top hook
          _TraceDot(0.5, 0.12),  // 2: top
          _TraceDot(0.5, 0.38),  // 3: upper stem
          _TraceDot(0.5, 0.62),  // 4: lower stem
          _TraceDot(0.5, 0.88),  // 5: base
          _TraceDot(0.35, 0.88), // 6: base left
          _TraceDot(0.65, 0.88), // 7: base right
        ];
      case '2':
        return [
          _TraceDot(0.32, 0.2),  // 1: top left arc
          _TraceDot(0.5, 0.1),   // 2: top
          _TraceDot(0.68, 0.2),  // 3: top right arc
          _TraceDot(0.65, 0.38), // 4: right
          _TraceDot(0.5, 0.52),  // 5: center
          _TraceDot(0.35, 0.65), // 6: sweep left
          _TraceDot(0.28, 0.78), // 7: bottom left
          _TraceDot(0.5, 0.88),  // 8: bottom center
          _TraceDot(0.7, 0.88),  // 9: bottom right
        ];
      case '3':
        return [
          _TraceDot(0.32, 0.18), // 1: top left
          _TraceDot(0.5, 0.1),   // 2: top
          _TraceDot(0.68, 0.2),  // 3: top right
          _TraceDot(0.58, 0.38), // 4: right upper
          _TraceDot(0.45, 0.5),  // 5: center cross
          _TraceDot(0.58, 0.62), // 6: right lower
          _TraceDot(0.68, 0.78), // 7: bottom right
          _TraceDot(0.5, 0.88),  // 8: bottom
          _TraceDot(0.32, 0.8),  // 9: bottom left
        ];
      default:
        return [_TraceDot(0.5, 0.5)];
    }
  }
}

class _TraceDot {
  _TraceDot(this.x, this.y);
  final double x;
  final double y;
  bool lit = false;
}
