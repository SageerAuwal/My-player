import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_player/app.dart';

void main() {
  testWidgets('AuraPlayerApp initial shell smoke test and tab switching', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AuraPlayerApp(),
      ),
    );

    // First screen is SplashScreen
    expect(find.text('Aura'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Play  •  Listen  •  Understand'), findsOneWidget);

    // Fast-forward past splash delay
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Now on MainNavigationShell (HomeScreen)
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();

    // Verify Settings screen loaded
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('App Visual Theme'), findsOneWidget);
  });
}
