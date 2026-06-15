import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/sprout_theme.dart';
import '../../widgets/common/sprout_button.dart';
import '../../widgets/mascot/bud_mascot.dart';
import '../../widgets/reward/celebration_overlay.dart';

/// Activity 5: Animal Sounds
///
/// 4 large animal cards. Every tap is "correct" — pure exploration.
/// Bud mimics the animal, the animal name appears with a bounce,
/// and TTS speaks the animal sound description.
///
/// Design notes:
///   - No wrong answers possible — lowest-friction activity
///   - After 12 taps (any combination), celebration triggers
///   - Animal illustrations drawn with CustomPainter (no assets)
///   - Great for very young children (18m–3yr) who can't yet "match"
class AnimalSoundScreen extends StatefulWidget {
  const AnimalSoundScreen({super.key});

  @override
  State<AnimalSoundScreen> createState() => _AnimalSoundScreenState();
}

class _AnimalSoundScreenState extends State<AnimalSoundScreen>
    with TickerProviderStateMixin {
  static const _animals = [
    _Animal('Dog', '🐕', 'Woof woof!', kSkyBlue),
    _Animal('Cat', '🐱', 'Meow!', kSoftPurple),
    _Animal('Cow', '🐄', 'Moooo!', kSunshineYellow),
    _Animal('Duck', '🦆', 'Quack quack!', kSproutGreen),
    _Animal('Lion', '🦁', 'Roarrr!', kOrange),
    _Animal('Frog', '🐸', 'Ribbit!', kSproutGreenDark),
  ];

  int _totalTaps = 0;
  static const _tapsToComplete = 10;

  _Animal? _lastTapped;
  BudState _budState = BudState.idle;
  bool _showCelebration = false;
  bool _showLabel = false;

  // Per-card bounce controllers
  final Map<String, AnimationController> _bounceCtrs = {};
  final Map<String, Animation<double>> _bounceAnims = {};

  // Label fade controller
  late final AnimationController _labelCtrl;
  late final Animation<double> _labelAnim;

  @override
  void initState() {
    super.initState();
    // analytics.logEvent('activity_started', {'activity': 'animal_sounds'});

    _labelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _labelAnim = CurvedAnimation(parent: _labelCtrl, curve: Curves.elasticOut);

    for (final animal in _animals) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _bounceCtrs[animal.name] = ctrl;
      _bounceAnims[animal.name] = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.15), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().startActivity();
      AudioService.instance.speak('Tap the animals to hear their sounds!');
    });
  }

  void _onAnimalTapped(_Animal animal) async {
    // analytics.logEvent('item_tapped', {'correct': true, 'animal': animal.name, 'attempt': _totalTaps + 1});
    final provider = context.read<ActivityProvider>();
    await AudioService.instance.playTapAck();
    _bounceCtrs[animal.name]?.forward(from: 0);

    if (!mounted) return;
    setState(() {
      _lastTapped = animal;
      _budState = BudState.happy;
      _showLabel = true;
    });

    _labelCtrl.forward(from: 0);
    await AudioService.instance.playCorrect();
    await AudioService.instance.speak('The ${animal.name} says ${animal.sound}');

    if (!mounted) return;
    setState(() => _budState = BudState.celebrating);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _budState = BudState.idle);

    _totalTaps++;
    provider.recordCorrect();

    if (_totalTaps >= _tapsToComplete) {
      // analytics.logEvent('activity_completed', {'duration_seconds': provider.elapsedSeconds, 'score': _totalTaps});
      // analytics.logEvent('reward_shown', {'activity': 'animal_sounds'});
      await Future.delayed(const Duration(milliseconds: 300));
      await AudioService.instance.playCelebrate();
      if (!mounted) return;
      provider.completeActivity();
      setState(() {
        _budState = BudState.celebrating;
        _showCelebration = true;
      });
    }

    // Hide label after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _lastTapped == animal) {
        setState(() => _showLabel = false);
      }
    });
  }

  void _restart() {
    _totalTaps = 0;
    setState(() {
      _showCelebration = false;
      _showLabel = false;
      _lastTapped = null;
    });
    context.read<ActivityProvider>().startActivity();
    AudioService.instance.speak('Let\'s hear more animals!');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    for (final ctrl in _bounceCtrs.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ActivityHeader(
                  accentColor: kAnimalColor,
                  scoreLabel: '🎵 $_totalTaps',
                ),
                _buildBudAndLabel(),
                const SizedBox(height: kSpacingM),
                Expanded(child: _buildAnimalGrid()),
                _buildProgressBar(),
                const SizedBox(height: kSpacingL),
              ],
            ),
            if (_showCelebration)
              Positioned.fill(
                child: CelebrationOverlay(
                  message: 'You heard all the animals! 🦁',
                  onDismiss: _restart,
                ),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildBudAndLabel() {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BudMascot(state: _budState, size: 100),

          // Sound label bubble — appears above Bud
          if (_showLabel && _lastTapped != null)
            Positioned(
              top: 0,
              child: ScaleTransition(
                scale: _labelAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpacingM,
                    vertical: kSpacingS,
                  ),
                  decoration: BoxDecoration(
                    color: _lastTapped!.color,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: _lastTapped!.color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '"${_lastTapped!.sound}"',
                    style: kBodyStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimalGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: kSpacingM,
        crossAxisSpacing: kSpacingM,
        children: _animals.map((a) => _buildAnimalCard(a)).toList(),
      ),
    );
  }

  Widget _buildAnimalCard(_Animal animal) {
    final bounce = _bounceAnims[animal.name];
    return AnimatedBuilder(
      animation: bounce ?? kAlwaysDismissedAnimation,
      builder: (context, _) => Transform.scale(
        scale: bounce?.value ?? 1.0,
        child: GestureDetector(
          onTap: () => _onAnimalTapped(animal),
          child: Container(
            decoration: BoxDecoration(
              color: animal.color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(kCardRadius),
              boxShadow: [
                BoxShadow(
                  color: animal.color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(animal.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: kSpacingS),
                Text(
                  animal.name,
                  style: kBodyStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_totalTaps / _tapsToComplete).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
      child: Column(
        children: [
          Text(
            'Keep tapping! $_totalTaps / $_tapsToComplete',
            style: kBodyStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: kSpacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation(kSproutGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _Animal {
  const _Animal(this.name, this.emoji, this.sound, this.color);
  final String name;
  final String emoji;
  final String sound;
  final Color color;
}
