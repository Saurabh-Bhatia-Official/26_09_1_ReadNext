import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/app.dart';
import 'package:read_next/core/constants/app_constants.dart';

void main() {
  testWidgets('ReadNext smoke test, dashboard, and navigation destinations', (WidgetTester tester) async {
    // Set a realistic desktop window size for desktop testing
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

    // Verify ReadNext app branding is visible
    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text(AppConstants.appTagline), findsOneWidget);

    // Verify Quick Actions are present on the Home Dashboard
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Merge PDF'), findsOneWidget);
    expect(find.text('Split PDF'), findsOneWidget);
    expect(find.text('Compress PDF'), findsOneWidget);
    expect(find.text('Convert PDF'), findsOneWidget);
    expect(find.text('OCR Text'), findsOneWidget);

    // Verify Navigation Rail items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Viewer'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap on 'Tools' in NavigationRail
    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();

    // Verify Tools Hub has loaded
    expect(find.text('ReadNext Tools Hub'), findsOneWidget);
    expect(find.text('Organize'), findsOneWidget);
    expect(find.text('Optimize'), findsOneWidget);
    expect(find.text('Convert'), findsOneWidget);
    expect(find.text('Edit & Security'), findsOneWidget);
    expect(find.text('OCR (Text)'), findsOneWidget);
  });
}
