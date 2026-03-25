import 'package:brick_breaker/features/game/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplashScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );
    expect(find.text('BRICK'), findsOneWidget);
  });
}
