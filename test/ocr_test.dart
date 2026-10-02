import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:read_next/services/ocr/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OcrService Tests', () {
    test('OcrService parses image input and recognizes text inside image', () async {
      final logoFile = File('assets/images/logo_icon.png');
      expect(await logoFile.exists(), isTrue);
      final bytes = await logoFile.readAsBytes();

      final results = await OcrService.performOcr(
        inputBytes: bytes,
        language: OcrLanguage.english,
      );

      expect(results, isNotEmpty);
      expect(results.first.pageNumber, equals(1));
      expect(results.first.confidence, greaterThan(0.5));

      // Test creating searchable PDF from image + OCR results
      final searchablePdf = await OcrService.createSearchablePdf(
        originalBytes: bytes,
        ocrResults: results,
      );
      expect(searchablePdf, isNotEmpty);
      expect(searchablePdf.length, greaterThan(100));
    });

    test('OcrService extracts text from PDF document', () async {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: pw_pdf.PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Text('Sample PDF Document for OCR Verification'),
            );
          },
        ),
      );
      final pdfBytes = await doc.save();

      final results = await OcrService.performOcr(
        inputBytes: pdfBytes,
        language: OcrLanguage.english,
      );

      expect(results, isNotEmpty);
      expect(results.first.pageNumber, equals(1));
      expect(results.first.extractedText, isNotEmpty);
      expect(results.first.lines, isNotEmpty);
    });
  });
}
