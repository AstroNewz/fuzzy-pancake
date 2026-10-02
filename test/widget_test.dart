import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smashdeck/core/theme/app_theme.dart';
import 'package:smashdeck/features/auth/welcome_splash_screen.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('SmashDeck WelcomeSplashScreen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ProviderScope(child: WelcomeSplashScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify WelcomeSplashScreen components
    expect(find.text('ENTER SMASHDECK'), findsOneWidget);
    expect(find.text('COLLEGIATE SQUAD LADDER'), findsOneWidget);
  });
}
