import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_smashers/main.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ShuttleSmashersApp());

    // Verify that the app name is displayed on splash screen
    expect(find.text('SHUTTLE SMASHERS'), findsOneWidget);
    expect(find.text('Score. Compete. Win.'), findsOneWidget);
  });
}
