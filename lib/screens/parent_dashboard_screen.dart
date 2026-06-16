import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../theme/sprout_theme.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late bool _soundEnabled;
  late bool _hapticsEnabled;
  final TextEditingController _feedbackController = TextEditingController();
  List<String> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _soundEnabled = StorageService.instance.isSoundEnabled();
    _hapticsEnabled = StorageService.instance.isHapticsEnabled();
    _feedbackList = StorageService.instance.getParentFeedback();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _saveFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    await StorageService.instance.addParentFeedback(text);
    _feedbackController.clear();
    setState(() {
      _feedbackList = StorageService.instance.getParentFeedback();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Observation saved! Thank you for testing with Sprout. 🌱',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        backgroundColor: kSproutGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Learning Progress?',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: kTextDark),
        ),
        content: Text(
          'This will clear all earned stars, completion records, settings, and usability notes. This action cannot be undone.',
          style: GoogleFonts.nunito(color: kTextDark.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: kTextDark),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kCoralPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.instance.clearAll();
              setState(() {
                _soundEnabled = true;
                _hapticsEnabled = true;
                _feedbackList = [];
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Progress has been reset completely.',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: kTextDark,
                ),
              );
            },
            child: Text(
              'Reset Everything',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cumulativeScore = StorageService.instance.getCumulativeScore();
    final completedActivities = StorageService.instance.getCompletedActivities();
    const totalActivitiesCount = 6;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Grown-Ups Dashboard 📊',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: kTextDark,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: kTextDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section: Progress Summary ───────────────────────────────────
            _buildSectionHeader('Child Progress Insights'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: _borderBorderSideColor,
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(kSpacingL),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatPill('⭐ Stars', '$cumulativeScore'),
                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                        _buildStatPill(
                          '🚀 Progress',
                          '${completedActivities.length} / $totalActivitiesCount Done',
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildActivityStatusRow('Shapes Activity 🔷', completedActivities.contains('shapes')),
                    _buildActivityStatusRow('Counting Activity ⭐', completedActivities.contains('counting')),
                    _buildActivityStatusRow('Colors Activity 🎨', completedActivities.contains('colors')),
                    _buildActivityStatusRow('Tracing Activity ✏️', completedActivities.contains('trace')),
                    _buildActivityStatusRow('Animal Sounds 🐸', completedActivities.contains('animals')),
                    _buildActivityStatusRow('Camera Explorer 📷', completedActivities.contains('camera')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSpacingL),

            // ── Section: Settings ───────────────────────────────────────────
            _buildSectionHeader('Preferences & Accessibility'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: _borderBorderSideColor,
              ),
              color: Colors.white,
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: kSproutGreen,
                    title: Text(
                      'Voice Narration & Sound Effects',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: kTextDark),
                    ),
                    subtitle: Text(
                      'Toggles background cues, voice hints, and math wave audio',
                      style: GoogleFonts.nunito(fontSize: 12),
                    ),
                    value: _soundEnabled,
                    onChanged: (val) async {
                      await StorageService.instance.setSoundEnabled(val);
                      setState(() => _soundEnabled = val);
                      if (val) {
                        AudioService.instance.playTapAck();
                      }
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeColor: kSproutGreen,
                    title: Text(
                      'Tactile Haptics',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: kTextDark),
                    ),
                    subtitle: Text(
                      'Enables physical vibration feedback on taps and scores',
                      style: GoogleFonts.nunito(fontSize: 12),
                    ),
                    value: _hapticsEnabled,
                    onChanged: (val) async {
                      await StorageService.instance.setHapticsEnabled(val);
                      setState(() => _hapticsEnabled = val);
                      if (val) {
                        HapticFeedback.mediumImpact();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: kSpacingL),

            // ── Section: Parent Usability Session Testing ───────────────────
            _buildSectionHeader('Parent Usability Logs'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: _borderBorderSideColor,
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(kSpacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Prototyping & Usability Sessions 📝',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add observational notes during co-playing sessions with your child. Document points of confusion or high-delight moments to support quick feature iteration.',
                      style: GoogleFonts.nunito(
                        color: kTextDark.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      style: GoogleFonts.nunito(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Struggled with dragging shapes initially, loved Bud\'s wiggle animation...',
                        hintStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kSproutGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSproutGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _saveFeedback,
                      child: Text(
                        'Save Notes',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_feedbackList.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        'Saved Observations:',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _feedbackList.length,
                        itemBuilder: (ctx, idx) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('📝 ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    _feedbackList[idx],
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: kTextDark.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSpacingL),

            // ── Section: Privacy & Safety ──────────────────────────────────
            _buildSectionHeader('Privacy-by-Design Checklist'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: _borderBorderSideColor,
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(kSpacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacyItem('🔒 Parental Gate Enabled', 'Prevents toddlers from entering settings or launching device integrations alone.'),
                    _buildPrivacyItem('🚫 100% Offline execution', 'No internet connection required. No personal data leaves the device.'),
                    _buildPrivacyItem('🤖 On-device Machine Learning', 'Computer vision and camera stream analysis occurs fully offline in volatile memory.'),
                    _buildPrivacyItem('📊 Minimalist Local Tracking', 'Stores only cumulative stars and completion status flags locally via SharedPreferences.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSpacingXL),

            // ── Section: Danger Zone ────────────────────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kCoralPink,
                surfaceTintColor: Colors.white,
                side: const BorderSide(color: kCoralPink, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: _confirmReset,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Reset All Learning Progress',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            const SizedBox(height: kSpacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String val) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: kTextDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStatusRow(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: completed ? kSproutGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (completed) ...[
                  const Icon(Icons.check_circle, color: kSproutGreen, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Completed',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kSproutGreenDark,
                    ),
                  ),
                ] else ...[
                  Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Not Started',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: kTextDark,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: kTextDark.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Border side config
const _borderBorderSideColor = BorderSide(
  color: Color(0xFFE9ECEF),
  width: 1.5,
);
