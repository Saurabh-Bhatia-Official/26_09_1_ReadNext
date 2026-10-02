import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/app.dart';
import 'package:read_next/core/constants/app_constants.dart';

void main() {
  testWidgets('Left panel can be hidden and unhidden via button and Ctrl+B shortcut', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: ReadNextApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify software logo is rendered in the top header
    expect(find.byType(Image), findsWidgets);
    expect(find.text(AppConstants.appName), findsWidgets);

    // 2. Initially left panel (NavigationRail) is visible
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Viewer'), findsOneWidget);

    // 3. Find the left panel toggle button by tooltip
    final toggleButton = find.byTooltip('Hide Left Panel (Ctrl+B)');
    expect(toggleButton, findsOneWidget);

    // 4. Tap toggle button to hide left panel
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Verify left panel is now hidden
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip('Show Left Panel (Ctrl+B)'), findsOneWidget);

    // 5. Tap toggle button again to unhide left panel
    await tester.tap(find.byTooltip('Show Left Panel (Ctrl+B)'));
    await tester.pumpAndSettle();

    // Verify left panel is visible again
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    // 6. Test Ctrl+B keyboard shortcut to toggle left panel
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    // Verify left panel is hidden via Ctrl+B
    expect(find.byType(NavigationRail), findsNothing);
  });
}
