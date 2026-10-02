import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/services/pdf/pdf_converter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF to Word (.docx) Conversion Tests', () {
    test('PdfConverterService.pdfToWordDocx generates valid OpenXML docx with coherent text', () async {
      final sampleFile = File('assets/sample.pdf');
      expect(await sampleFile.exists(), isTrue);

      final pdfBytes = await sampleFile.readAsBytes();
      double? lastProgress;

      final docxBytes = await PdfConverterService.pdfToWordDocx(
        pdfBytes: pdfBytes,
        onProgress: (p) => lastProgress = p,
      );

      expect(docxBytes, isNotEmpty);
      expect(docxBytes.length, greaterThan(1500));
      expect(lastProgress, equals(1.0));

      // Decode the generated DOCX ZIP archive
      final archive = ZipDecoder().decodeBytes(docxBytes);
      final fileNames = archive.files.map((f) => f.name).toSet();

      // Verify all required OpenXML parts for Microsoft Word / LibreOffice
      expect(fileNames.contains('[Content_Types].xml'), isTrue);
      expect(fileNames.contains('_rels/.rels'), isTrue);
      expect(fileNames.contains('word/_rels/document.xml.rels'), isTrue);
      expect(fileNames.contains('word/styles.xml'), isTrue);
      expect(fileNames.contains('word/settings.xml'), isTrue);
      expect(fileNames.contains('word/fontTable.xml'), isTrue);
      expect(fileNames.contains('word/document.xml'), isTrue);

      // Verify document.xml content and proper paragraph reconstruction
      final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
      final docXml = utf8.decode(docFile.content as List<int>);

      // Verify headings and key phrases are reconstructed together, not split into single words
      expect(docXml.contains('READNEXT SPECIFICATION'), isTrue);
      expect(docXml.contains('Welcome to ReadNext'), isTrue);
      expect(docXml.contains('Architecture Overview &amp; Search Targets') || docXml.contains('Architecture Overview'), isTrue);
      expect(docXml.contains('INV-2026-90412'), isTrue);
      expect(docXml.contains('w:pStyle w:val="Heading1"'), isTrue);
      expect(docXml.contains('w:br w:type="page"'), isTrue);
      expect(docXml.contains('w:sectPr'), isTrue);
    });

    test('extractPagesFromPdfBytes extracts coherent sentences and paragraphs from PDF', () async {
      final sampleFile = File('assets/sample.pdf');
      final pdfBytes = await sampleFile.readAsBytes();

      final pages = PdfConverterService.extractPagesFromPdfBytes(pdfBytes);
      expect(pages, isNotEmpty);
      expect(pages.length, equals(4));

      // First page contains specification title and intro paragraph
      final page1 = pages[0];
      expect(page1.contains('READNEXT SPECIFICATION'), isTrue);
      expect(page1.contains('Welcome to ReadNext'), isTrue);

      // Second page contains Architecture title and Invoice details
      final page2 = pages[1];
      expect(page2.contains('Architecture Overview'), isTrue);
      expect(page2.contains('INV-2026-90412'), isTrue);
    });

    test('isCleanReadableText distinguishes coherent language from garbled random characters', () {
      const validText = 'ReadNext is an enterprise-grade PDF reader and utility suite engineered with Flutter.';
      expect(PdfConverterService.isCleanReadableText(validText), isTrue);

      const garbledControlChars = '\x00\x01\x02\x03\x04\x05\x12%&@#\$!RandomCorruptedData';
      expect(PdfConverterService.isCleanReadableText(garbledControlChars), isFalse);

      const cipherNoise = '!@#\$%^&*()_+~`|}{[]:;?><,./-=+~`#\$%^&*()';
      expect(PdfConverterService.isCleanReadableText(cipherNoise), isFalse);

      const emptyText = '   \n  \t  ';
      expect(PdfConverterService.isCleanReadableText(emptyText), isFalse);
    });

    test('isPdfEncrypted correctly identifies encrypted PDF headers or trailers', () {
      final unencryptedBytes = Uint8List.fromList(utf8.encode('%PDF-1.4\n1 0 obj\n<</Type/Catalog>>\nendobj\ntrailer\n<</Size 2>>\n%%EOF'));
      expect(PdfConverterService.isPdfEncrypted(unencryptedBytes), isFalse);

      final encryptedBytes = Uint8List.fromList(utf8.encode('%PDF-1.7\n1 0 obj\n<</Type/Catalog>>\nendobj\ntrailer\n<</Size 10/Encrypt 5 0 R>>\n%%EOF'));
      expect(PdfConverterService.isPdfEncrypted(encryptedBytes), isTrue);
    });

    test('sanitizeTextToReadable removes non-printable control codes while preserving valid text', () {
      const dirty = 'Hello\x00\x01\x02\x03 World\x1B!';
      final clean = PdfConverterService.sanitizeTextToReadable(dirty);
      expect(clean, equals('Hello World!'));
    });
  });
}
