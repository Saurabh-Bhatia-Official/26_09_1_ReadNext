import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/app.dart';

void main() {
  testWidgets('MainShell navigation rail does not overflow when window height is small', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 376.8); // 376.8 - 48 header = 328.8
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: ReadNextApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
