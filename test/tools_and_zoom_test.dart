import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/ui/screens/tools_hub_screen.dart';
import 'package:read_next/ui/widgets/dialogs/quick_tools_dialog.dart';
import 'package:read_next/ui/widgets/tools/small_tool_tile.dart';
import 'package:read_next/ui/widgets/tools/tools_catalog.dart';

void main() {
  group('ToolsHubScreen and SmallToolTiles Tests', () {
    testWidgets('ToolsHubScreen shows all 20 tools in one screen with small grid tiles', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ToolsHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('ReadNext Tools Hub'), findsOneWidget);

      // Verify all tools in one: all 20 ToolItem instances are rendered as SmallToolTile widgets
      expect(find.byType(SmallToolTile), findsNWidgets(ToolsCatalog.allTools.length));
      expect(ToolsCatalog.allTools.length, 20);

      // Verify sample tools are visible as small grid tiles
      expect(find.text('Merge PDF'), findsOneWidget);
      expect(find.text('Split PDF'), findsOneWidget);
      expect(find.text('Compress PDF'), findsOneWidget);
      expect(find.text('PDF to Word'), findsOneWidget);
      expect(find.text('Watermark PDF'), findsOneWidget);
      expect(find.text('OCR Extraction'), findsOneWidget);
      expect(find.text('Batch Queue'), findsOneWidget);

      // Test Category Filtering
      await tester.tap(find.text('Optimize'));
      await tester.pumpAndSettle();

      // Only Optimize tools (Compress PDF, Repair PDF) should be shown
      expect(find.byType(SmallToolTile), findsNWidgets(2));
      expect(find.text('Compress PDF'), findsOneWidget);
      expect(find.text('Repair PDF'), findsOneWidget);
      expect(find.text('Merge PDF'), findsNothing);

      // Return to 'All'
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byType(SmallToolTile), findsNWidgets(20));

      // Test Search Filtering
      await tester.enterText(find.byType(TextField), 'Watermark PDF');
      await tester.pumpAndSettle();

      expect(find.byType(SmallToolTile), findsNWidgets(1));
      expect(
        find.descendant(of: find.byType(SmallToolTile), matching: find.text('Watermark PDF')),
        findsOneWidget,
      );
    });

    testWidgets('QuickToolsDialog displays small grid tiles and filters', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickToolsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All PDF Tools'), findsOneWidget);
      expect(find.byType(SmallToolTile), findsNWidgets(20));
    });
  });
}
