import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/data/models/bookmark_model.dart';
import 'package:read_next/data/models/pdf_document_meta.dart';
import 'package:read_next/services/pdf/i_pdf_engine.dart';
import 'package:read_next/services/pdf/pdf_converter_service.dart';
import 'package:read_next/state/document_provider.dart';
import 'package:read_next/ui/widgets/toolbar/main_toolbar.dart';

class FakePdfEngine implements IPdfEngine {
  @override
  bool get isOpen => true;
  @override
  int get pageCount => 10;
  @override
  PdfDocumentMeta get metadata => const PdfDocumentMeta(title: 'Test Doc', pageCount: 10, filePath: '/test/doc.pdf', fileSize: 1024);
  @override
  String? get currentPath => '/test/doc.pdf';
  @override
  Uint8List? get currentBytes => Uint8List(0);
  @override
  Future<void> close() async {}
  @override
  Future<String> extractText(int pageNumber) async => '';
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

class MockDocumentNotifier extends DocumentNotifier {
  @override
  DocumentState build() {
    return DocumentState(
      isLoading: false,
      engine: FakePdfEngine(),
      metadata: const PdfDocumentMeta(title: 'Test Doc', pageCount: 10, filePath: '/test/doc.pdf', fileSize: 1024),
      currentPath: '/test/doc.pdf',
    );
  }
}

void main() {
  testWidgets('MainToolbar renders initial tools when no document is open', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MainToolbar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial tools without doc
    expect(find.text('All Tools'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    expect(find.byIcon(Icons.view_sidebar), findsOneWidget);
  });

  testWidgets('MainToolbar renders all tools and text labels when document is open', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentProvider.overrideWith(() => MockDocumentNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MainToolbar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify prominent visible text labels
    expect(find.text('All Tools'), findsOneWidget);
    expect(find.textContaining('Page 1 /'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1.5x HD'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Annotate'), findsOneWidget);

    // Verify file and navigation tools
    expect(find.byIcon(Icons.save_outlined), findsOneWidget);
    expect(find.byIcon(Icons.print_outlined), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byIcon(Icons.first_page), findsOneWidget);
    expect(find.byIcon(Icons.navigate_before), findsOneWidget);
    expect(find.byIcon(Icons.navigate_next), findsOneWidget);
    expect(find.byIcon(Icons.last_page), findsOneWidget);

    // Verify zoom and view tools
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.fit_screen), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
  });
}
