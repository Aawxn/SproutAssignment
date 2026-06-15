import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/sprout_theme.dart';
import '../../services/audio_service.dart';

/// Reusable Sprout button — bounces on tap.
class SproutButton extends StatefulWidget {
  const SproutButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = kSproutGreen,
    this.textColor = Colors.white,
    this.icon,
    this.minSize = kMinTapTarget,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final String? icon;
  final double minSize;

  @override
  State<SproutButton> createState() => _SproutButtonState();
}

class _SproutButtonState extends State<SproutButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    AudioService.instance.playTapAck();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          constraints: BoxConstraints(
            minWidth: widget.minSize,
            minHeight: widget.minSize,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingL,
            vertical: kSpacingM,
          ),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(kBorderRadius),
            boxShadow: kCardShadow(widget.color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Text(widget.icon!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: kSpacingS),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: kLabelStyle.copyWith(color: widget.textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Try again" bubble — gentle, never a red X.
class TryAgainBubble extends StatefulWidget {
  const TryAgainBubble({super.key, this.message = 'Hmm, try again! 🌱'});
  final String message;

  @override
  State<TryAgainBubble> createState() => _TryAgainBubbleState();
}

class _TryAgainBubbleState extends State<TryAgainBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.3)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: kSpacingL, vertical: kSpacingM),
          decoration: BoxDecoration(
            color: kSunshineYellow,
            borderRadius: BorderRadius.circular(kBorderRadius),
            boxShadow: kCardShadow(kSunshineYellow),
          ),
          child: Text(
            widget.message,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5A3E00),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Responsive activity header bar — back button + label + score badge.
/// Uses [LayoutBuilder] so nothing overflows on any screen.
class ActivityHeader extends StatelessWidget {
  const ActivityHeader({
    super.key,
    required this.accentColor,
    required this.scoreLabel,
  });

  final Color accentColor;
  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          kSpacingM, kSpacingS, kSpacingM, 0),
      child: Row(
        children: [
          // Back button — fixed 48×48 to never overflow
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: kSoftShadow,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 22, color: kTextDark),
            ),
          ),
          const Spacer(),
          // Score badge — constrained width
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(
                horizontal: kSpacingM, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              scoreLabel,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dot-style progress row — used by activities with rounds.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.total,
    required this.completed,
    required this.color,
  });

  final int total;
  final int completed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final done = i < completed;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: done ? 22 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: done
                ? color
                : color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
