import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/audio_service.dart';
import '../../services/ml_label_service.dart';
import '../../theme/sprout_theme.dart';
import '../../widgets/mascot/bud_mascot.dart';
import '../../widgets/reward/celebration_overlay.dart';

/// Task 4: Camera + On-Device ML Labeling Screen
///
/// Flow:
///   1. Request CAMERA permission at runtime (Android 6+)
///   2. Camera initializes (rear, medium resolution)
///   3. Child frames an object and taps the shutter
///   4. ML Kit runs on-device inference
///   5. Bud reacts, speaks the top label
///   6. Child taps the label card → celebration
///
/// Performance:
///   - RepaintBoundary wraps camera preview
///   - ResolutionPreset.medium (640×480) for fast ML inference
///   - Camera released on lifecycle pause
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _CamState { requestingPermission, denied, initializing, ready }

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  _CamState _camState = _CamState.requestingPermission;

  bool _isAnalyzing = false;
  bool _showCelebration = false;
  List<_DisplayLabel> _labels = [];
  BudState _budState = BudState.idle;
  String _budMessage = 'Point at something and tap!';

  // Shutter flash
  late final AnimationController _shutterCtrl;
  late final Animation<double> _shutterAnim;

  // Result panel slide-up
  late final AnimationController _resultCtrl;
  late final Animation<Offset> _resultSlide;
  late final Animation<double> _resultFade;

  int _found = 0;
  static const _goal = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _shutterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shutterAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shutterCtrl, curve: Curves.easeOut),
    );

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _resultSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutBack));
    _resultFade = CurvedAnimation(
      parent: _resultCtrl,
      curve: const Interval(0, 0.5),
    );

    MlLabelService.instance.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().startActivity();
      _requestPermissionAndInit();
    });
  }

  Future<void> _requestPermissionAndInit() async {
    // Check current status first
    var status = await Permission.camera.status;

    if (status.isDenied) {
      // Request at runtime
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    if (status.isGranted) {
      setState(() => _camState = _CamState.initializing);
      await _initCamera();
    } else if (status.isPermanentlyDenied) {
      setState(() => _camState = _CamState.denied);
    } else {
      // Denied once — show denied state with option to open settings
      setState(() => _camState = _CamState.denied);
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _camState = _CamState.denied;
            _budMessage = 'No camera found on this device.';
          });
        }
        return;
      }

      // Prefer rear camera
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        rear,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) setState(() => _camState = _CamState.ready);
    } catch (e) {
      if (mounted) {
        setState(() {
          _camState = _CamState.denied;
          _budMessage = 'Camera couldn\'t start. Try again!';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed &&
        _camState == _CamState.ready) {
      _initCamera();
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_isAnalyzing ||
        _cameraController == null ||
        _camState != _CamState.ready) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _labels = [];
      _budState = BudState.thinking;
      _budMessage = 'Looking...';
    });

    await _shutterCtrl.forward(from: 0);
    await _shutterCtrl.reverse();
    await AudioService.instance.playTapAck();

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final rawResults = await MlLabelService.instance.analyzeImage(inputImage);

      if (!mounted) return;

      if (rawResults.isEmpty) {
        setState(() {
          _budState = BudState.encouraging;
          _budMessage = 'Hmm, nothing found!\nTry again!';
          _isAnalyzing = false;
        });
        await AudioService.instance.playTryAgain();
        await AudioService.instance
            .speak('I can\'t tell what that is! Point at something!');
        return;
      }

      final top = rawResults.first;
      if (!mounted) return;
      setState(() {
        _labels = rawResults
            .map((r) => _DisplayLabel(name: r.displayName, confidence: r.confidence))
            .toList();
        _budState = BudState.happy;
        _budMessage = 'I see something!\nIs it ${top.displayName}?';
        _isAnalyzing = false;
      });

      await _resultCtrl.forward(from: 0);
      await AudioService.instance.playCorrect();
      await AudioService.instance.speak(
        'I see ${top.displayName}! Tap it to confirm!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _budState = BudState.encouraging;
        _budMessage = 'Oops! Let\'s try again!';
      });
      await AudioService.instance.playTryAgain();
    }
  }

  void _onLabelConfirmed(_DisplayLabel label) async {
    final provider = context.read<ActivityProvider>();
    await AudioService.instance.playCorrect();
    await AudioService.instance
        .speak('Yes! That\'s ${label.name}! Great eyes!');

    if (!mounted) return;
    setState(() => _budState = BudState.celebrating);
    _found++;
    provider.recordCorrect();

    if (_found >= _goal) {
      await AudioService.instance.playCelebrate();
      if (!mounted) return;
      provider.completeActivity();
      setState(() => _showCelebration = true);
    } else {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _labels = [];
        _budState = BudState.idle;
        _budMessage = 'Great! Find another thing!';
      });
      _resultCtrl.reverse();
    }
  }

  void _restart() {
    _found = 0;
    setState(() {
      _showCelebration = false;
      _labels = [];
      _budState = BudState.idle;
      _budMessage = 'Point at something and tap!';
    });
    context.read<ActivityProvider>().startActivity();
    _resultCtrl.reverse();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _shutterCtrl.dispose();
    _resultCtrl.dispose();
    MlLabelService.instance.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildCameraLayer(),
            _buildUILayer(),
            if (_showCelebration)
              Positioned.fill(
                child: CelebrationOverlay(
                  message: 'Explorer badge earned! 🔭',
                  onDismiss: _restart,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_camState == _CamState.requestingPermission ||
        _camState == _CamState.initializing) {
      return const Positioned.fill(
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: kCameraColor),
          ),
        ),
      );
    }
    if (_camState == _CamState.denied) {
      return _buildPermissionDenied();
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Positioned.fill(
        child: ColoredBox(color: Colors.black),
      );
    }
    return Positioned.fill(
      child: RepaintBoundary(
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xFF111418),
        child: Padding(
          padding: const EdgeInsets.all(kSpacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📷', style: TextStyle(fontSize: 64)),
              const SizedBox(height: kSpacingL),
              Text(
                'Camera permission needed',
                style: kHeadingStyle.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kSpacingM),
              Text(
                'To explore with the camera, please allow access.',
                style: kBodyStyle.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kSpacingXL),
              FilledButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: kCameraColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 52),
                  textStyle: kLabelStyle,
                ),
              ),
              const SizedBox(height: kSpacingM),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Go back',
                  style: kBodyStyle.copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUILayer() {
    return Column(
      children: [
        _buildTopBar(),
        _buildBudBubble(),
        const Spacer(),
        if (_labels.isNotEmpty)
          SlideTransition(
            position: _resultSlide,
            child: FadeTransition(
              opacity: _resultFade,
              child: _buildResultPanel(),
            ),
          )
        else if (_camState == _CamState.ready)
          _buildShutter(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: kSpacingM, vertical: kSpacingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 22, color: Colors.white),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSpacingM, vertical: 6),
            decoration: BoxDecoration(
              color: kCameraColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🔍 $_found / $_goal',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: kSpacingM, vertical: kSpacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudMascot(state: _budState, size: 64),
          const SizedBox(width: kSpacingS),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpacingM, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              child: Text(
                _budMessage,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutter() {
    return GestureDetector(
      onTap: _captureAndAnalyze,
      child: AnimatedBuilder(
        animation: _shutterAnim,
        builder: (_, child) => Opacity(
          opacity: 1.0 - _shutterAnim.value * 0.6,
          child: child,
        ),
        child: Container(
          width: 78, height: 78,
          decoration: BoxDecoration(
            color: _isAnalyzing ? kCameraColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            _isAnalyzing
                ? Icons.hourglass_top_rounded
                : Icons.camera_alt_rounded,
            size: 36,
            color: _isAnalyzing ? Colors.white : kSproutGreenDark,
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpacingM),
      padding: const EdgeInsets.fromLTRB(
          kSpacingL, kSpacingM, kSpacingL, kSpacingL),
      decoration: BoxDecoration(
        color: kWarmCream,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kBorderRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: kSpacingM),
          Text('I think I see…', style: kBodyStyle),
          const SizedBox(height: kSpacingM),
          ..._labels.asMap().entries.map((e) {
            final i = e.key;
            final label = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: kSpacingS),
              child: GestureDetector(
                onTap: () => _onLabelConfirmed(label),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSpacingL, vertical: kSpacingM),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? kCameraColor
                        : kCameraColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: i == 0
                        ? null
                        : Border.all(
                            color: kCameraColor.withValues(alpha: 0.4),
                            width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label.name,
                          style: GoogleFonts.nunito(
                            fontSize: i == 0 ? 18 : 15,
                            fontWeight: FontWeight.w800,
                            color: i == 0 ? Colors.white : kCameraColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: kSpacingS),
                      Text(
                        label.confidencePercent,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: i == 0
                              ? Colors.white70
                              : kTextLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DisplayLabel {
  const _DisplayLabel({required this.name, required this.confidence});
  final String name;
  final double confidence;
  String get confidencePercent => '${(confidence * 100).round()}%';
}
