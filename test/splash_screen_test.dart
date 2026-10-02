import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/app.dart';
import 'package:read_next/core/constants/app_constants.dart';
import 'package:read_next/core/theme/app_theme.dart';
import 'package:read_next/state/settings_provider.dart';
import 'package:read_next/ui/screens/main_shell.dart';
import 'package:read_next/ui/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen and Corporate Theme Tests', () {
    testWidgets('SplashScreen displays branding, logo, and progress indicator', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(
              duration: Duration(milliseconds: 1000),
            ),
          ),
        ),
      );

      // Verify branding elements and white background on splash
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Read. Manage. Move Forward.'), findsOneWidget);
      expect(find.text('Skip to App'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Let animation complete and verify navigation to MainShell
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('SplashScreen Skip button navigates immediately to MainShell', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(
              duration: Duration(seconds: 10),
            ),
          ),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Skip to App'), findsOneWidget);

      // Tap skip button
      await tester.tap(find.text('Skip to App'));
      await tester.pumpAndSettle();

      // Should have transitioned to MainShell
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('ReadNextApp boots with Corporate Theme as default', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: ReadNextApp(skipSplash: true),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, Brightness.dark);
      expect(materialApp.theme?.scaffoldBackgroundColor, const Color(0xFF090E17));
    });

    test('SettingsState defaults to corporate theme and supports copyWith', () {
      const state = SettingsState();
      expect(state.themeMode, AppThemeMode.corporate);

      final updated = state.copyWith(themeMode: AppThemeMode.light);
      expect(updated.themeMode, AppThemeMode.light);

      final corporate = updated.copyWith(themeMode: AppThemeMode.corporate);
      expect(corporate.themeMode, AppThemeMode.corporate);
    });
  });
}
