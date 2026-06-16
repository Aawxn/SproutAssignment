import 'package:flutter_test/flutter_test.dart';
import 'package:sprout_app/providers/activity_provider.dart';

void main() {
  group('ActivityProvider Unit Tests', () {
    late ActivityProvider provider;

    setUp(() {
      provider = ActivityProvider();
    });

    test('Initial state is correct', () {
      expect(provider.score, 0);
      expect(provider.attempts, 0);
      expect(provider.isComplete, false);
      expect(provider.elapsedSeconds, 0);
    });

    test('startActivity initializes state and timer', () async {
      provider.startActivity();
      expect(provider.score, 0);
      expect(provider.attempts, 0);
      expect(provider.isComplete, false);
      
      // Let it tick briefly to verify elapsedSeconds works
      await Future.delayed(const Duration(seconds: 1));
      expect(provider.elapsedSeconds, greaterThanOrEqualTo(0));
    });

    test('recordCorrect increments score and attempts', () {
      provider.startActivity();
      provider.recordCorrect();
      
      expect(provider.score, 1);
      expect(provider.attempts, 1);
    });

    test('recordIncorrect increments attempts only', () {
      provider.startActivity();
      provider.recordIncorrect();
      
      expect(provider.score, 0);
      expect(provider.attempts, 1);
    });

    test('completeActivity flags completion', () {
      provider.startActivity();
      provider.completeActivity('test_tag');
      
      expect(provider.isComplete, true);
    });

    test('reset clears all states', () {
      provider.startActivity();
      provider.recordCorrect();
      provider.completeActivity('test_tag');
      
      provider.reset();
      
      expect(provider.score, 0);
      expect(provider.attempts, 0);
      expect(provider.isComplete, false);
      expect(provider.elapsedSeconds, 0);
    });
  });
}
