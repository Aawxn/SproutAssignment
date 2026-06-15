import 'package:flutter/material.dart';

/// Shared activity state — tracks score, attempts, and completion.
/// Kept intentionally thin: only state, no UI logic.
class ActivityProvider extends ChangeNotifier {
  int _score = 0;
  int _attempts = 0;
  bool _isComplete = false;
  DateTime? _startTime;

  int get score => _score;
  int get attempts => _attempts;
  bool get isComplete => _isComplete;

  int get elapsedSeconds =>
      _startTime == null ? 0 : DateTime.now().difference(_startTime!).inSeconds;

  void startActivity() {
    _score = 0;
    _attempts = 0;
    _isComplete = false;
    _startTime = DateTime.now();
    notifyListeners();
  }

  void recordCorrect() {
    _score++;
    _attempts++;
    notifyListeners();
  }

  void recordIncorrect() {
    _attempts++;
    notifyListeners();
  }

  void completeActivity() {
    _isComplete = true;
    notifyListeners();
  }

  void reset() {
    _score = 0;
    _attempts = 0;
    _isComplete = false;
    _startTime = null;
    notifyListeners();
  }
}
