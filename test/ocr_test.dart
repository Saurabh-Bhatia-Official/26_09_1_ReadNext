import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:read_next/services/ocr/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OcrService Tests', () {
    test('OcrService parses image input and recognizes text inside image', () async {
      // Create a test image using PowerShell System.Drawing (containing shapes/artwork and text)
      final tempImgPath = '${Directory.systemTemp.path}/test_ocr_unit.png';
      await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '& {',
          '  Add-Type -AssemblyName System.Drawing;',
          '  \$bmp = New-Object System.Drawing.Bitmap 400, 100;',
          '  \$g = [System.Drawing.Graphics]::FromImage(\$bmp);',
          '  \$g.Clear([System.Drawing.Color]::LightGray);',
          '  \$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Blue);',
          '  \$g.FillEllipse(\$brush, 10, 10, 50, 50);', // Visual graphic to ignore
          '  \$font = New-Object System.Drawing.Font(\'Arial\', [float]20);',
          '  \$textBrush = [System.Drawing.Brushes]::Black;',
          '  \$g.DrawString(\'ReadNext Invoice #123\', \$font, \$textBrush, 70.0, 30.0);', // Text inside image
          '  \$g.Dispose();',
          '  \$bmp.Save(\'$tempImgPath\', [System.Drawing.Imaging.ImageFormat]::Png);',
          '  \$bmp.Dispose();',
          '}',
        ],
        runInShell: true,
      );

      final imgFile = File(tempImgPath);
      if (await imgFile.exists()) {
        final bytes = await imgFile.readAsBytes();
        final results = await OcrService.performOcr(
          inputBytes: bytes,
          language: OcrLanguage.english,
        );

        expect(results, isNotEmpty);
        expect(results.first.pageNumber, equals(1));
        // The graphic (blue circle) is ignored, and text inside the image is recognized
        expect(results.first.extractedText.toLowerCase(), contains('readnext'));
        expect(results.first.lines, isNotEmpty);
        expect(results.first.confidence, greaterThan(0.8));

        // Test creating searchable PDF from image + OCR results
        final searchablePdf = await OcrService.createSearchablePdf(
          originalBytes: bytes,
          ocrResults: results,
        );
        expect(searchablePdf, isNotEmpty);
        expect(searchablePdf.length, greaterThan(100));

        // Clean up
        try {
          await imgFile.delete();
        } catch (_) {}
      }
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
