import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';

void main() {
  testWidgets('Initial pump test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PosApp());

    // Verify app starts
    expect(find.text('POS'), findsWidgets);
  });
}
