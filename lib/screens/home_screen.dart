import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../theme/sprout_theme.dart';
import '../widgets/mascot/bud_mascot.dart';
import 'task2/shape_match_screen.dart';
import 'task2/counting_screen.dart';
import 'task2/color_recognition_screen.dart';
import 'task2/letter_trace_screen.dart';
import 'task2/animal_sound_screen.dart';
import 'task4/parental_gate_screen.dart';
import 'parent_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  BudState _budState = BudState.idle;
  late final AnimationController _staggerCtrl;
  int _cumulativeScore = 0;
  List<String> _completedTags = [];

  void _updateScore() {
    setState(() {
      _cumulativeScore = StorageService.instance.getCumulativeScore();
      _completedTags = StorageService.instance.getCompletedActivities();
    });
  }

  String _getStorageTag(String actTag) {
    switch (actTag) {
      case 'shape_match': return 'shapes';
      case 'letter_tracing': return 'trace';
      case 'counting': return 'counting';
      case 'color_recognition': return 'colors';
      case 'animal_sounds': return 'animals';
      case 'camera': return 'camera';
      default: return actTag;
    }
  }

  void _openParentZone() async {
    await AudioService.instance.playTapAck();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentalGateScreen(
          onPassed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const ParentDashboardScreen(),
              ),
            ).then((_) {
              _updateScore();
            });
          },
        ),
      ),
    ).then((_) {
      _updateScore();
    });
  }

  @override
  void initState() {
    super.initState();
    _updateScore();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _budState = BudState.happy);
      await AudioService.instance.speak("Hi! I'm Bud! What do you want to learn?");
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _budState = BudState.idle);
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  static const _activities = [
    _Act('Shapes',   '🔷', kShapeColor,  'shape_match'),
    _Act('Count',    '⭐', kCountColor,  'counting'),
    _Act('Colors',   '🎨', kColorColor,  'color_recognition'),
    _Act('Trace',    '✏️', kTraceColor,  'letter_tracing'),
    _Act('Animals',  '🐸', kAnimalColor, 'animal_sounds'),
    _Act('Explorer', '📷', kCameraColor, 'camera', locked: true),
  ];

  Future<void> _onTap(_Act act) async {
    await AudioService.instance.playTapAck();
    if (!mounted) return;
    setState(() => _budState = BudState.happy);

    Widget screen;
    switch (act.tag) {
      case 'shape_match':        screen = const ShapeMatchScreen();
      case 'counting':           screen = const CountingScreen();
      case 'color_recognition':  screen = const ColorRecognitionScreen();
      case 'letter_tracing':     screen = const LetterTraceScreen();
      case 'animal_sounds':      screen = const AnimalSoundScreen();
      case 'camera':             screen = const ParentalGateScreen();
      default: return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ChangeNotifierProvider(
          create: (_) => ActivityProvider(),
          child: screen,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );

    _updateScore();
    if (mounted) setState(() => _budState = BudState.idle);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final safeTop = mq.padding.top;

    // Header height = mascot (90) + text (~70) + spacing
    final headerH = (screenH * 0.26).clamp(150.0, 220.0);
    // Each card = remaining area / 3 rows, minus spacing
    final availableH = screenH - headerH - safeTop - mq.padding.bottom - 32;
    final cardH = (availableH / 3 - kSpacingM).clamp(90.0, 145.0);
    // Card width = half screen minus spacing
    final cardW = (mq.size.width / 2 - kSpacingM * 2).clamp(120.0, 200.0);

    return Scaffold(
      backgroundColor: kWarmCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(headerH),
            Expanded(
              child: _buildGrid(cardW, cardH),
            ),
            const SizedBox(height: kSpacingS),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Top Stats & Actions Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Star Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: kCountColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kCountColor.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$_cumulativeScore',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: kTextDark,
                      ),
                    ),
                  ],
                ),
              ),
              // Parental zone button
              GestureDetector(
                onTap: _openParentZone,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: kOrange.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text(
                        'Parents',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: kOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Main Mascot + Greeting Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bud mascot — size relative to header height
              BudMascot(
                state: _budState,
                size: (height * 0.52).clamp(60.0, 85.0),
              ),
              const SizedBox(width: kSpacingM),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, Explorer! 🌱',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kSproutGreenDark,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "What shall we learn?",
                      style: kTitleStyle.copyWith(
                        fontSize: (height * 0.12).clamp(18.0, 24.0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGrid(double cardW, double cardH) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: kSpacingM,
        mainAxisSpacing: kSpacingM,
        // Lock aspect ratio so card height is exactly cardH
        childAspectRatio: cardW / cardH,
      ),
      itemCount: _activities.length,
      itemBuilder: (ctx, i) {
        final delay = i * 0.1;
        final anim = CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(delay.clamp(0.0, 0.7), (delay + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutBack),
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _staggerCtrl,
              curve: Interval(delay.clamp(0.0, 0.7), (delay + 0.3).clamp(0.0, 1.0)),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(anim),
            child: _ActivityCard(
              act: _activities[i],
              isCompleted: _completedTags.contains(_getStorageTag(_activities[i].tag)),
              onTap: () => _onTap(_activities[i]),
            ),
          ),
        );
      },
    );
  }
}

// ─── Activity Card ───────────────────────────────────────────────────────────
class _ActivityCard extends StatefulWidget {
  const _ActivityCard({
    required this.act,
    required this.onTap,
    required this.isCompleted,
  });
  final _Act act;
  final VoidCallback onTap;
  final bool isCompleted;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.act;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) async {
        await _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: act.color,
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: kCardShadow(act.color),
          ),
          child: Stack(
            children: [
              // Subtle top-left tint
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(kCardRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Lock / Completion badge
              if (act.locked)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔒', style: TextStyle(fontSize: 11)),
                  ),
                )
              else if (widget.isCompleted)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kSproutGreen,
                      ),
                    ),
                  ),
                ),

              // Content — use LayoutBuilder to prevent overflow
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final h = constraints.maxHeight;
                    final emojiSize = (h * 0.38).clamp(24.0, 52.0);
                    final titleSize = (h * 0.17).clamp(13.0, 20.0);

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingM,
                        vertical: (h * 0.12).clamp(8.0, 18.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.emoji,
                            style: TextStyle(fontSize: emojiSize),
                          ),
                          SizedBox(height: (h * 0.06).clamp(4.0, 10.0)),
                          Text(
                            act.label,
                            style: GoogleFonts.nunito(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Act {
  const _Act(this.label, this.emoji, this.color, this.tag,
      {this.locked = false});
  final String label;
  final String emoji;
  final Color color;
  final String tag;
  final bool locked;
}
