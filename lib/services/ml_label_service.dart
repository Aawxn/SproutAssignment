import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// On-device image labeling service using ML Kit.
///
/// Architecture follows on-device inference pattern:
///   CameraImage → InputImage → ImageLabeler → labels
///
/// Key design decisions:
///   - On-device only — no cloud API calls (COPPA compliance)
///   - Threshold: 0.65 confidence minimum (reduces noise)
///   - Labels are filtered to child-friendly categories
///   - Singleton to avoid multiple labeler instances (memory)
///
/// Mirrors the ReMind face recognition pipeline pattern:
///   TFLite/ML Kit on-device inference, result callbacks, no PII.
class MlLabelService {
  MlLabelService._();
  static final MlLabelService instance = MlLabelService._();

  ImageLabeler? _labeler;
  bool _initialized = false;

  // Child-friendly label categories to surface
  static const _friendlyCategories = {
    'dog', 'cat', 'bird', 'fish', 'rabbit', 'hamster',
    'flower', 'tree', 'plant', 'grass', 'leaf',
    'apple', 'banana', 'orange', 'food', 'fruit',
    'car', 'toy', 'ball', 'book', 'cup',
    'person', 'hand', 'face',
    'table', 'chair', 'floor', 'sky', 'cloud',
    'red', 'blue', 'green', 'yellow',
  };

  // Child-friendly display names (map from ML Kit label to friendly name)
  static const _friendlyNames = {
    'dog': '🐕 Dog',
    'cat': '🐱 Cat',
    'bird': '🐦 Bird',
    'fish': '🐟 Fish',
    'flower': '🌸 Flower',
    'tree': '🌳 Tree',
    'apple': '🍎 Apple',
    'banana': '🍌 Banana',
    'car': '🚗 Car',
    'ball': '⚽ Ball',
    'book': '📚 Book',
    'person': '👤 Person',
    'hand': '✋ Hand',
    'sky': '☁️ Sky',
    'cloud': '☁️ Cloud',
  };

  static const double _confidenceThreshold = 0.65;
  static const int _maxLabels = 5;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Use base model (bundled with ML Kit — no download needed on first launch)
    final options = ImageLabelerOptions(
      confidenceThreshold: _confidenceThreshold,
    );
    _labeler = ImageLabeler(options: options);
  }

  /// Analyze an [InputImage] and return top child-friendly labels.
  /// Returns empty list on error — never throws.
  Future<List<LabelResult>> analyzeImage(InputImage image) async {
    if (_labeler == null) await init();

    try {
      final rawLabels = await _labeler!.processImage(image);

      final results = rawLabels
          .where((l) {
            final lower = l.label.toLowerCase();
            // Include if it matches a friendly category or directly maps
            return _friendlyNames.containsKey(lower) ||
                _friendlyCategories.any((cat) => lower.contains(cat));
          })
          .map((l) {
            final lower = l.label.toLowerCase();
            final friendlyKey = _friendlyNames.keys
                .firstWhere((k) => lower.contains(k), orElse: () => l.label);
            return LabelResult(
              rawLabel: l.label,
              displayName: _friendlyNames[friendlyKey] ?? l.label,
              confidence: l.confidence,
            );
          })
          .take(_maxLabels)
          .toList();

      // Sort by confidence descending
      results.sort((a, b) => b.confidence.compareTo(a.confidence));
      return results;
    } catch (e) {
      debugPrint('[MlLabelService] Error: $e');
      return [];
    }
  }

  void dispose() {
    _labeler?.close();
    _labeler = null;
    _initialized = false;
  }
}

/// Public result model for [MlLabelService.analyzeImage]
class LabelResult {
  const LabelResult({
    required this.rawLabel,
    required this.displayName,
    required this.confidence,
  });

  final String rawLabel;
  final String displayName;
  final double confidence;

  String get confidencePercent => '${(confidence * 100).round()}%';
}
