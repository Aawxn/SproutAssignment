import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for tracking toddler learning progress and preferences.
///
/// Anchors the following features:
///   - Persistence of total stars earned (celebrated in the home dashboard)
///   - Completed activity tags to visual lock/unlock or trace progress
///   - Privacy safety configuration (COPPA alignment)
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  static const String _keyScore = 'sprout_cumulative_score';
  static const String _keyCompleted = 'sprout_completed_activities';
  static const String _keySoundEnabled = 'sprout_sound_enabled';
  static const String _keyHapticsEnabled = 'sprout_haptics_enabled';
  static const String _keyParentFeedback = 'sprout_parent_feedback';

  /// Pre-warm local storage
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Get total stars earned across all sessions
  int getCumulativeScore() {
    return _prefs?.getInt(_keyScore) ?? 0;
  }

  /// Add new stars to persistence
  Future<void> addScore(int value) async {
    if (!_initialized) await init();
    final current = getCumulativeScore();
    await _prefs?.setInt(_keyScore, current + value);
  }

  /// Get list of completed activity tags
  List<String> getCompletedActivities() {
    return _prefs?.getStringList(_keyCompleted) ?? [];
  }

  /// Mark an activity as completed
  Future<void> markActivityComplete(String tag) async {
    if (!_initialized) await init();
    final list = getCompletedActivities();
    if (!list.contains(tag)) {
      list.add(tag);
      await _prefs?.setStringList(_keyCompleted, list);
    }
  }

  /// Sound settings
  bool isSoundEnabled() {
    return _prefs?.getBool(_keySoundEnabled) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (!_initialized) await init();
    await _prefs?.setBool(_keySoundEnabled, enabled);
  }

  /// Haptics settings
  bool isHapticsEnabled() {
    return _prefs?.getBool(_keyHapticsEnabled) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    if (!_initialized) await init();
    await _prefs?.setBool(_keyHapticsEnabled, enabled);
  }

  /// Parent usability feedback notes
  List<String> getParentFeedback() {
    return _prefs?.getStringList(_keyParentFeedback) ?? [];
  }

  Future<void> addParentFeedback(String text) async {
    if (!_initialized) await init();
    final list = getParentFeedback();
    list.add('${DateTime.now().toIso8601String().substring(0, 16)}: $text');
    await _prefs?.setStringList(_keyParentFeedback, list);
  }

  /// Clear progress (e.g. parent resetting stats)
  Future<void> clearAll() async {
    if (!_initialized) await init();
    await _prefs?.remove(_keyScore);
    await _prefs?.remove(_keyCompleted);
    await _prefs?.remove(_keySoundEnabled);
    await _prefs?.remove(_keyHapticsEnabled);
    await _prefs?.remove(_keyParentFeedback);
  }
}
