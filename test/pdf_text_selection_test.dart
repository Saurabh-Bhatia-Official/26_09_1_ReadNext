import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/services/pdf/pdf_converter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Text Extraction and Positional Lines Tests', () {
    test('Extracts page lines with positional and font metadata from sample.pdf', () async {
      final file = File('assets/sample.pdf');
      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();
      final pageLines = PdfConverterService.extractPageLinesFromPdfBytes(bytes);
      expect(pageLines.length, equals(4));

      final lines = List<PdfTextLine>.from(pageLines[0]);
      expect(lines, isNotEmpty);

      // Verify page 1 content
      final allText = lines.map((l) => l.text).join(' ');
      expect(allText.contains('READNEXT SPECIFICATION'), isTrue);
      expect(allText.contains('Advanced Professional'), isTrue);
      expect(allText.contains('PDF Viewer'), isTrue);
      expect(allText.contains('Welcome to ReadNext'), isTrue);

      // Sort lines top-to-bottom (higher y is higher on the page in PDF coordinates)
      lines.sort((a, b) => b.y.compareTo(a.y));
      expect(lines.first.fontSize, greaterThanOrEqualTo(16.0));

      // Verify all pages have valid text lines
      for (int i = 0; i < pageLines.length; i++) {
        expect(pageLines[i], isNotEmpty, reason: 'Page ${i + 1} should have text lines');
        for (final line in pageLines[i]) {
          expect(line.text.trim(), isNotEmpty);
          expect(line.fontSize, greaterThan(0));
        }
      }
    });

    test('extractPagesFromPdfBytes returns full text per page matching line extractions', () async {
      final file = File('assets/sample.pdf');
      final bytes = await file.readAsBytes();

      final pages = PdfConverterService.extractPagesFromPdfBytes(bytes);
      expect(pages.length, equals(4));

      // Page 1
      expect(pages[0].contains('READNEXT SPECIFICATION'), isTrue);
      expect(pages[0].contains('Welcome to ReadNext'), isTrue);

      // Page 2
      expect(pages[1].contains('Architecture Overview'), isTrue);
      expect(pages[1].contains('INV-2026-90412'), isTrue);

      // Page 3
      expect(pages[2].contains('Annotation and Markup Capabilities'), isTrue);

      // Page 4
      expect(pages[3].contains('Verification & Form Acceptance'), isTrue);
    });
  });
}
