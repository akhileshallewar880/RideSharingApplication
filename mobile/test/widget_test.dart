// This is a basic Flutter test file.
// The project uses a custom structure, so these tests need to be updated.

import 'package:flutter_test/flutter_test.dart';
import 'package:allapalli_ride/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VanYatraApp());

    // Verify that splash screen elements are present
    expect(find.byType(VanYatraApp), findsOneWidget);
  });
}
