import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Initial pump test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PosApp());

    // Wait for the mock API timers to finish and the future builder to resolve
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify app starts and shows Login screen since storage is empty
    expect(find.text('Masuk'), findsWidgets);
  });
}
