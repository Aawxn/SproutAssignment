import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/sprout_theme.dart';

/// Celebration overlay — shown on activity completion.
/// Stars burst from center, Bud dances above the message.
/// [RepaintBoundary] isolates particle repaints from parent tree.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.onDismiss,
    this.message = 'Amazing! 🌟',
  });

  final VoidCallback onDismiss;
  final String message;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _particleCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Entry animation (card pops in)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.3),
      ),
    );

    // Particle animation (stars burst outward)
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Generate 30 particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(rng: _rng));
    }

    _entryCtrl.forward();
    _particleCtrl.forward().then((_) {
      // Loop particles 2×, then auto-dismiss after 3s total
      if (mounted) _particleCtrl.forward(from: 0);
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: Stack(
            children: [
              // Particle layer
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _particleCtrl,
                  builder: (context, _) => CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleCtrl.value,
                    ),
                    size: MediaQuery.of(context).size,
                  ),
                ),
              ),

              // Card
              Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(kSpacingXL),
                    decoration: BoxDecoration(
                      color: kWarmCream,
                      borderRadius: BorderRadius.circular(kBorderRadius * 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: kSproutGreen.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: kSproutGreenDark,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: kSpacingL),
                        const Text('⭐ ⭐ ⭐', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: kSpacingL),
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: kSproutGreen,
                              borderRadius:
                                  BorderRadius.circular(kBorderRadius),
                              boxShadow: kCardShadow(kSproutGreenDark),
                            ),
                            child: Text(
                              'Play Again! 🌱',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({required math.Random rng})
      : angle = rng.nextDouble() * 2 * math.pi,
        speed = 0.3 + rng.nextDouble() * 0.7,
        color = _colors[rng.nextInt(_colors.length)],
        size = 6 + rng.nextDouble() * 10,
        shape = rng.nextInt(3);

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final int shape; // 0=circle, 1=star, 2=square

  static const _colors = [
    kSunshineYellow,
    kCoralPink,
    kSkyBlue,
    kSoftPurple,
    kSproutGreen,
    kOrange,
  ];
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxRadius = size.shortestSide * 0.55;

    for (final p in particles) {
      final t = (progress + p.speed * 0.3) % 1.0;
      final r = t * maxRadius * p.speed;
      final alpha = (1.0 - t * t).clamp(0.0, 1.0);

      final x = cx + math.cos(p.angle) * r;
      final y = cy + math.sin(p.angle) * r;

      final paint = Paint()..color = p.color.withValues(alpha: alpha);

      switch (p.shape) {
        case 0:
          canvas.drawCircle(Offset(x, y), p.size * (1 - t * 0.5), paint);
        case 1:
          _drawStar(canvas, x, y, p.size * (1 - t * 0.5), paint);
        case 2:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x, y),
              width: p.size * (1 - t * 0.5),
              height: p.size * (1 - t * 0.5),
            ),
            paint,
          );
      }
    }
  }

  void _drawStar(Canvas canvas, double x, double y, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;
      final ox = x + math.cos(outerAngle) * r;
      final oy = y + math.sin(outerAngle) * r;
      final ix = x + math.cos(innerAngle) * r * 0.4;
      final iy = y + math.sin(innerAngle) * r * 0.4;
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
