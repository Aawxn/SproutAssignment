import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/sprout_theme.dart';
import '../../widgets/mascot/bud_mascot.dart';
import '../../widgets/common/sprout_button.dart';
import '../../widgets/reward/celebration_overlay.dart';

/// Activity 2: Counting Objects
///
/// Shows 1–9 floating fruits. Child taps each to count along
/// (each tap highlights the fruit + plays a tick sound).
/// Then taps the correct number button from 3 choices.
///
/// Design choices:
///   - Objects float with subtle idle animation (alive, not static)
///   - Each tap on an object counts it and highlights it
///   - Number buttons are oversized (100×100dp)
///   - Wrong number: gentle boing + Bud encourages, tries again
class CountingScreen extends StatefulWidget {
  const CountingScreen({super.key});

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen>
    with TickerProviderStateMixin {
  static const _emojis = ['🍎', '🍊', '🍋', '🌟', '🦋', '🌸', '🐸', '🍇', '🐥'];

  final _rng = math.Random();
  late int _targetCount;
  late List<int> _options;
  late String _emoji;
  late List<_FloatingItem> _items;

  int _tappedCount = 0;
  BudState _budState = BudState.idle;
  bool _showTryAgain = false;
  bool _showCelebration = false;
  bool _answered = false;
  int _round = 0;
  static const _totalRounds = 4;

  // Float animation (all items share one controller)
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    // analytics.logEvent('activity_started', {'activity': 'counting'});

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().startActivity();
      _generateRound();
    });
  }

  void _generateRound() {
    _targetCount = 1 + _rng.nextInt(5 + _round.clamp(0, 4)); // gets harder
    _targetCount = _targetCount.clamp(1, 9);
    _emoji = _emojis[_rng.nextInt(_emojis.length)];
    _tappedCount = 0;
    _answered = false;

    // Generate 3 number options including the correct answer
    final wrong1 = (_targetCount + 1 + _rng.nextInt(3)).clamp(1, 9);
    var wrong2 = (_targetCount - 1 - _rng.nextInt(2)).clamp(1, 9);
    if (wrong2 == wrong1 || wrong2 == _targetCount) wrong2 = _targetCount + 2;
    wrong2 = wrong2.clamp(1, 9);

    _options = [_targetCount, wrong1, wrong2]..shuffle(_rng);
    if (_options.toSet().length < 3) {
      // Fallback for edge values
      _options = [_targetCount,
        (_targetCount + 1).clamp(1, 9),
        (_targetCount + 2).clamp(1, 9)]..shuffle(_rng);
    }

    // Generate floating positions for items
    _items = List.generate(_targetCount, (i) {
      return _FloatingItem(
        emoji: _emoji,
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: _rng.nextDouble() * 0.85,
        floatOffset: _rng.nextDouble() * math.pi * 2,
        floatAmplitude: 4 + _rng.nextDouble() * 6,
      );
    });

    setState(() {
      _budState = BudState.thinking;
      _showTryAgain = false;
    });

    AudioService.instance.speak('How many can you count?');
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _budState = BudState.idle);
    });
  }

  void _onItemTapped(int index) async {
    if (_answered || _items[index].counted) return;
    await AudioService.instance.playTapAck();

    setState(() {
      _items[index].counted = true;
      _tappedCount++;
    });

    // Bud gets excited as count rises
    if (_tappedCount == _targetCount) {
      setState(() => _budState = BudState.happy);
      await AudioService.instance.speak('Now pick the number!');
    }
  }

  void _onNumberTapped(int number) async {
    if (_answered) return;
    // analytics.logEvent('item_tapped', {'correct': number == _targetCount, 'attempt': context.read<ActivityProvider>().attempts + 1});
    await AudioService.instance.playTapAck();
    _answered = true;

    if (number == _targetCount) {
      _onCorrect();
    } else {
      _onWrong();
    }
  }

  void _onCorrect() async {
    context.read<ActivityProvider>().recordCorrect();
    setState(() => _budState = BudState.happy);
    await AudioService.instance.playCorrect();
    await AudioService.instance.speak(
        'Yes! There are $_targetCount ${_emoji}s!');

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _round++;

    if (_round >= _totalRounds) {
      // analytics.logEvent('activity_completed', {'duration_seconds': context.read<ActivityProvider>().elapsedSeconds, 'score': context.read<ActivityProvider>().score});
      // analytics.logEvent('reward_shown', {'activity': 'counting'});
      context.read<ActivityProvider>().completeActivity();
      await AudioService.instance.playCelebrate();
      setState(() {
        _budState = BudState.celebrating;
        _showCelebration = true;
      });
    } else {
      _generateRound();
    }
  }

  void _onWrong() async {
    context.read<ActivityProvider>().recordIncorrect();
    await AudioService.instance.playTryAgain();
    setState(() {
      _budState = BudState.encouraging;
      _showTryAgain = true;
      _answered = false; // Let them try again
    });

    await AudioService.instance.speak('Hmm, try counting again!');
    // Reset counts so child can recount
    setState(() {
      for (final item in _items) {
        item.counted = false;
      }
      _tappedCount = 0;
    });
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
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepCream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Consumer<ActivityProvider>(
                  builder: (_, p, __) => ActivityHeader(
                    accentColor: kCountColor,
                    scoreLabel: '⭐ ${p.score}',
                  ),
                ),
                const SizedBox(height: kSpacingS),
                _buildBudRow(),
                const SizedBox(height: kSpacingS),
                _buildCountingArea(),
                const SizedBox(height: kSpacingM),
                if (_showTryAgain)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
                    child: TryAgainBubble(
                      message: 'Try counting again! 🌱',
                    ),
                  ),
                const SizedBox(height: kSpacingM),
                _buildNumberButtons(),
                const SizedBox(height: kSpacingM),
                ProgressDots(
                  total: _totalRounds,
                  completed: _round,
                  color: kCountColor,
                ),
                const SizedBox(height: kSpacingM),
              ],
            ),
            if (_showCelebration)
              Positioned.fill(
                child: CelebrationOverlay(
                  message: 'Amazing counting! 🎊',
                  onDismiss: _restart,
                ),
              ),
          ],
        ),
      ),
    );
  }




  Widget _buildBudRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BudMascot(state: _budState, size: 90),
        const SizedBox(width: kSpacingM),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacingM,
              vertical: kSpacingS,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
              ],
            ),
            child: Text(
              'Tap each $_emoji to count!',
              style: kBodyStyle,
            ),
          ),
        ),
        const SizedBox(width: kSpacingM),
      ],
    );
  }

  Widget _buildCountingArea() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _floatCtrl,
            builder: (context, _) {
              return Stack(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final floatY = math.sin(
                        _floatCtrl.value * math.pi + item.floatOffset,
                      ) *
                      item.floatAmplitude;

                  return Positioned(
                    left: item.x * constraints.maxWidth - 30,
                    top: item.y * constraints.maxHeight - 30 + floatY,
                    child: GestureDetector(
                      onTap: () => _onItemTapped(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: item.counted
                              ? kSproutGreen.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.counted ? kSproutGreen : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.emoji,
                            style: TextStyle(
                              fontSize: item.counted ? 28 : 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNumberButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Button size = 1/4 of screen width, bounded
        final btnSize = (constraints.maxWidth / 4).clamp(64.0, 100.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _options.map((n) {
              return GestureDetector(
                onTap: () => _onNumberTapped(n),
                child: Container(
                  width: btnSize,
                  height: btnSize,
                  decoration: BoxDecoration(
                    color: kCountColor,
                    borderRadius: BorderRadius.circular(kCardRadius),
                    boxShadow: kCardShadow(kCountColor),
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        '$n',
                        style: kTitleStyle.copyWith(
                          fontSize: 40,
                          color: const Color(0xFF5A3E00),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Replaced by ProgressDots widget in build()
}

class _FloatingItem {
  _FloatingItem({
    required this.emoji,
    required this.x,
    required this.y,
    required this.floatOffset,
    required this.floatAmplitude,
  });

  final String emoji;
  final double x;
  final double y;
  final double floatOffset;
  final double floatAmplitude;
  bool counted = false;
}
