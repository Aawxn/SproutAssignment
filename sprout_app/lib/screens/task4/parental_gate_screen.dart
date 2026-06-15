import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/sprout_theme.dart';
import '../../widgets/common/sprout_button.dart';
import '../../widgets/mascot/bud_mascot.dart';
import 'camera_screen.dart';

/// Parental Gate Screen — required before camera activates.
///
/// Framed as a safety/privacy feature: "Ask a grown-up to help!"
/// The gate uses TWO adult-level tasks that toddlers cannot pass:
///   Option A: Tap 3 shapes in exact displayed order
///   Option B: Hold a button for 5 continuous seconds
///
/// Design rationale:
///   - Framed positively ("Let's ask a grown-up!") — not punitive
///   - Toddlers cannot sustain 5-second holds or remember shape sequences
///   - If failed, gentle reset — Bud encourages, no penalty
///   - On pass: camera opens with Bud celebration
///
/// Privacy note: This gate prevents accidental camera activation by
/// unsupervised toddlers, aligning with COPPA/GDPR-K requirements.
class ParentalGateScreen extends StatefulWidget {
  const ParentalGateScreen({super.key});

  @override
  State<ParentalGateScreen> createState() => _ParentalGateScreenState();
}

enum _GateMode { intro, shapeChallenge, holdChallenge }

class _ParentalGateScreenState extends State<ParentalGateScreen>
    with TickerProviderStateMixin {
  _GateMode _mode = _GateMode.intro;
  BudState _budState = BudState.idle;

  // ── Shape challenge state ─────────────────────────────────
  static const _allShapes = ['⭐', '■', '●', '▲', '♥'];
  late List<String> _requiredSequence;
  List<String> _tappedSequence = [];
  bool _shapeError = false;

  // ── Hold challenge state ──────────────────────────────────
  static const _holdDuration = 5; // seconds
  Timer? _holdTimer;
  Timer? _holdTickTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;

  // Intro bounce animation
  late final AnimationController _introCtrl;
  late final Animation<double> _introAnim;

  @override
  void initState() {
    super.initState();
    // analytics.logEvent('parental_gate_shown');
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _introAnim = CurvedAnimation(parent: _introCtrl, curve: Curves.elasticOut);
    _introCtrl.forward();

    _generateShapeSequence();
    AudioService.instance.speak(
      'Time to ask a grown-up! Can a parent help open the camera?',
    );
  }

  void _generateShapeSequence() {
    final shuffled = List.of(_allShapes)..shuffle();
    _requiredSequence = shuffled.take(3).toList();
  }

  // ── Shape challenge ────────────────────────────────────────
  void _onShapeTapped(String shape) async {
    await AudioService.instance.playTapAck();
    final expected = _requiredSequence[_tappedSequence.length];

    if (shape == expected) {
      setState(() {
        _tappedSequence.add(shape);
        _shapeError = false;
      });

      if (_tappedSequence.length == 3) {
        _onGatePass();
      }
    } else {
      setState(() {
        _shapeError = true;
        _tappedSequence = [];
      });
      await AudioService.instance.playTryAgain();
      await AudioService.instance.speak('Oops! Try again — tap them in order!');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _shapeError = false);
      });
    }
  }

  // ── Hold challenge ─────────────────────────────────────────
  void _onHoldStart() {
    if (_isHolding) return;
    _isHolding = true;
    _holdProgress = 0.0;

    _holdTickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _holdProgress += 0.1 / _holdDuration);
      if (_holdProgress >= 1.0) {
        _onHoldComplete();
      }
    });
  }

  void _onHoldEnd() {
    if (!_isHolding) return;
    _isHolding = false;
    _holdTimer?.cancel();
    _holdTickTimer?.cancel();

    if (_holdProgress < 1.0) {
      // Didn't hold long enough
      setState(() => _holdProgress = 0.0);
      AudioService.instance.speak('Keep holding! Don\'t let go!');
    }
  }

  void _onHoldComplete() {
    _holdTickTimer?.cancel();
    _holdTimer?.cancel();
    _isHolding = false;
    _onGatePass();
  }

  // ── Gate pass ─────────────────────────────────────────────
  void _onGatePass() async {
    // analytics.logEvent('parental_gate_passed');
    setState(() => _budState = BudState.celebrating);
    await AudioService.instance.playGatePass();
    await AudioService.instance.speak('Great job! Opening the camera!');
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ActivityProvider(),
          child: const CameraScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _holdTickTimer?.cancel();
    _introCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Column(
          children: [
            ActivityHeader(
              accentColor: kOrange,
              scoreLabel: '🔒 Gate',
            ),
            const Spacer(),
            ScaleTransition(
              scale: _introAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSpacingXL),
                child: Column(
                  children: [
                    BudMascot(state: _budState, size: 90),
                    const SizedBox(height: kSpacingM),
                    Text(
                      '🔒 Ask a Grown-Up!',
                      style: kTitleStyle.copyWith(color: kOrange),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingS),
                    Text(
                      'To keep you safe, a grown-up needs to open the camera.',
                      style: kBodyStyle,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSpacingXL),
            _buildModeSelector(),
            const SizedBox(height: kSpacingL),
            _buildChallenge(),
            const Spacer(),
          ],
        ),
      ),
    );
  }



  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeTab(
          label: 'Tap Shapes',
          icon: '⭐',
          selected: _mode == _GateMode.shapeChallenge,
          onTap: () => setState(() {
            _mode = _GateMode.shapeChallenge;
            _tappedSequence = [];
            _shapeError = false;
          }),
        ),
        const SizedBox(width: kSpacingM),
        _ModeTab(
          label: 'Hold Button',
          icon: '✋',
          selected: _mode == _GateMode.holdChallenge,
          onTap: () => setState(() {
            _mode = _GateMode.holdChallenge;
            _holdProgress = 0.0;
          }),
        ),
      ],
    );
  }

  Widget _buildChallenge() {
    switch (_mode) {
      case _GateMode.shapeChallenge:
        return _buildShapeChallenge();
      case _GateMode.holdChallenge:
        return _buildHoldChallenge();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildShapeChallenge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
      child: Column(
        children: [
          Text(
            'Tap these shapes in order:',
            style: kBodyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpacingM),

          // Required sequence display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_requiredSequence.length, (i) {
              final tapped = i < _tappedSequence.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: tapped ? kSproutGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _shapeError ? kCoralPink : kSproutGreen,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    tapped ? '✓' : _requiredSequence[i],
                    style: TextStyle(
                      fontSize: tapped ? 28 : 32,
                      color: tapped ? Colors.white : kTextDark,
                    ),
                  ),
                ),
              );
            }),
          ),

          if (_shapeError) ...[
            const SizedBox(height: kSpacingM),
            Text(
              'Hmm! Try again in the right order! 🌱',
              style: kBodyStyle.copyWith(color: kCoralPink),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: kSpacingL),

          // Tappable shape buttons (randomized order)
          Wrap(
            spacing: kSpacingM,
            runSpacing: kSpacingM,
            alignment: WrapAlignment.center,
            children: _allShapes.map((shape) {
              return GestureDetector(
                onTap: () => _onShapeTapped(shape),
                child: Container(
                  width: kMinTapTarget,
                  height: kMinTapTarget,
                  decoration: BoxDecoration(
                    color: kOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: Border.all(color: kOrange, width: 2),
                  ),
                  child: Center(
                    child: Text(shape, style: const TextStyle(fontSize: 34)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldChallenge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
      child: Column(
        children: [
          Text(
            'Hold this button for 5 seconds:',
            style: kBodyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpacingL),

          // Progress arc
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: _holdProgress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _holdProgress < 1.0 ? kOrange : kSproutGreen,
                  ),
                ),
                Center(
                  child: Text(
                    _isHolding
                        ? '${(_holdProgress * _holdDuration).ceil()}s'
                        : '${_holdDuration}s',
                    style: kTitleStyle.copyWith(fontSize: 40, color: kOrange),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: kSpacingXL),

          // Hold button
          GestureDetector(
            onTapDown: (_) => _onHoldStart(),
            onTapUp: (_) => _onHoldEnd(),
            onTapCancel: _onHoldEnd,
            child: Container(
              width: 180,
              height: 68,
              decoration: BoxDecoration(
                color: _isHolding ? kSproutGreen : kOrange,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: kCardShadow(_isHolding ? kSproutGreen : kOrange),
              ),
              child: Center(
                child: Text(
                  _isHolding ? 'Keep holding! ✋' : 'Hold me!',
                  style: kLabelStyle.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tab button for switching between challenge modes
class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: kSpacingM, vertical: kSpacingS),
        decoration: BoxDecoration(
          color: selected ? kOrange : Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: kOrange, width: 2),
          boxShadow: selected
              ? [BoxShadow(color: kOrange.withValues(alpha: 0.35), blurRadius: 8)]
              : [],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              label,
              style: kBodyStyle.copyWith(
                color: selected ? Colors.white : kOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
