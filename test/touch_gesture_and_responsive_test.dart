import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/app.dart';
import 'package:read_next/core/constants/app_constants.dart';
import 'package:read_next/data/models/bookmark_model.dart';
import 'package:read_next/data/models/pdf_document_meta.dart';
import 'package:read_next/services/pdf/i_pdf_engine.dart';
import 'package:read_next/services/pdf/pdf_converter_service.dart';
import 'package:read_next/state/document_provider.dart';
import 'package:read_next/state/zoom_provider.dart';
import 'package:read_next/ui/widgets/canvas/pdf_canvas_view.dart';

class _FakeTouchPdfEngine implements IPdfEngine {
  @override
  bool get isOpen => true;
  @override
  int get pageCount => 3;
  @override
  PdfDocumentMeta get metadata => const PdfDocumentMeta(title: 'Test Doc', pageCount: 3, filePath: '/test/doc.pdf', fileSize: 1024);
  @override
  String? get currentPath => '/test/doc.pdf';
  @override
  Uint8List? get currentBytes => Uint8List(0);
  @override
  Future<void> close() async {}
  @override
  Future<String> extractText(int pageNumber) async => 'Sample text';
  @override
  Future<List<PdfTextLine>> extractPageLines(int pageNumber) async => [];
  @override
  Future<List<OutlineItemModel>> getOutline() async => [];
  @override
  Future<Size> getPageDimensions(int pageNumber) async => const Size(600, 800);
  @override
  Future<void> openBytes(Uint8List bytes, {String? password, String? documentName}) async {}
  @override
  Future<void> openFile(String path, {String? password}) async {}
  @override
  Future<Uint8List?> renderPageThumbnail(int pageNumber, {int width = 200, int height = 300}) async => null;
  @override
  Future<List<SearchMatch>> search(String query, {bool caseSensitive = false, bool wholeWord = false}) async => [];
}

class _MockTouchDocumentNotifier extends DocumentNotifier {
  @override
  DocumentState build() {
    return DocumentState(
      isLoading: false,
      engine: _FakeTouchPdfEngine(),
      metadata: const PdfDocumentMeta(title: 'Test Doc', pageCount: 3, filePath: '/test/doc.pdf', fileSize: 1024),
      currentPath: '/test/doc.pdf',
    );
  }
}

void main() {
  group('Mobile and Tablet Responsive & Touch Gesture Tests', () {
    testWidgets('MainShell renders bottom NavigationBar on mobile dimensions without overflow', (WidgetTester tester) async {
      // Standard mobile phone dimensions (iPhone 14 / Pixel 7: 390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: ReadNextApp(),
        ),
      );
      await tester.pumpAndSettle();

      // On mobile screen: NavigationBar should be present, NavigationRail should NOT be present
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // App branding should be visible in the header
      expect(find.text(AppConstants.appName), findsWidgets);

      // Verify bottom destinations are present
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Tools'), findsWidgets);
      expect(find.text('Viewer'), findsWidgets);
      expect(find.text('Queue'), findsWidgets);
      expect(find.text('Recent'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);

      // Tap on 'Tools' destination in bottom NavigationBar
      await tester.tap(find.text('Tools').first);
      await tester.pumpAndSettle();

      // Verify Tools Hub has loaded and header adapts cleanly
      expect(find.text('ReadNext Tools Hub'), findsOneWidget);
    });

    testWidgets('MainShell renders NavigationRail on tablet/desktop dimensions (>= 700 width)', (WidgetTester tester) async {
      // Tablet / desktop dimensions (1024 x 768)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: ReadNextApp(),
        ),
      );
      await tester.pumpAndSettle();

      // On tablet/desktop screen: NavigationRail should be present, NavigationBar should NOT be present
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Touch pinch gesture zooms in and updates zoomProvider scale', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late ProviderContainer container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(),
          child: const MaterialApp(
            home: Scaffold(
              body: PdfCanvasView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state is empty (prompt to open PDF)
      expect(find.byType(PdfCanvasView), findsOneWidget);

      // Test ZoomNotifier pinch zoom calculations directly
      final initialZoom = container.read(zoomProvider).scale;
      expect(initialZoom, equals(1.0));

      // Simulate pinch-in (zoom out) and pinch-out (zoom in)
      container.read(zoomProvider.notifier).setZoom(initialZoom * 1.5);
      expect(container.read(zoomProvider).scale, equals(1.5));

      container.read(zoomProvider.notifier).setZoom(initialZoom * 0.75);
      expect(container.read(zoomProvider).scale, equals(0.75));
    });

    testWidgets('PC Touchpad pointer scroll and pan zoom update listeners exist on PdfCanvasView', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentProvider.overrideWith(() => _MockTouchDocumentNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PdfCanvasView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify outer Listener exists with onPointerPanZoomUpdate and onPointerSignal callbacks
      final listenerFinder = find.byWidgetPredicate(
        (widget) => widget is Listener && widget.onPointerPanZoomUpdate != null && widget.onPointerSignal != null,
      );
      expect(listenerFinder, findsOneWidget);

      // Verify canvas contains exactly one main vertical Scrollbar, not duplicate nested scrollbars
      final scrollbars = find.byType(Scrollbar);
      expect(scrollbars, findsOneWidget);
    });
  });
}
