import 'package:flutter_test/flutter_test.dart';
import 'package:sprout_app/main.dart';

void main() {
  testWidgets('Sprout app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SproutApp());
    // Basic smoke test — app builds without throwing
    expect(find.byType(SproutApp), findsOneWidget);
  });
}
