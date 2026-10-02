import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pfx;
import '../ocr/ocr_service.dart';

enum PdfPagePreset {
  a4,
  letter,
  fitToImage,
}

enum PdfPageOrientation {
  auto,
  portrait,
  landscape,
}

enum PdfImageFit {
  contain,
  cover,
  fill,
}

class ConvertedImage {
  final int pageNumber;
  final Uint8List bytes;
  final String format; // 'png', 'jpg', 'webp'
  final String fileName;

  ConvertedImage({
    required this.pageNumber,
    required this.bytes,
    required this.format,
    required this.fileName,
  });
}

class PdfTextLine {
  final String text;
  final double x;
  final double y; // in PDF points (0 is bottom, pageHeight is top)
  final double fontSize;

  const PdfTextLine({
    required this.text,
    this.x = 0.0,
    this.y = 0.0,
    this.fontSize = 12.0,
  });
}

class PdfConverterService {
  /// Converts PDF pages to rasterized images (PNG, JPG, etc.)
  static Future<List<ConvertedImage>> pdfToImages({
    required Uint8List pdfBytes,
    String format = 'png',
    List<int>? pageNumbers,
    double qualityScale = 2.0,
    void Function(double progress)? onProgress,
  }) async {
    final doc = await pfx.PdfDocument.openData(pdfBytes);
    final total = doc.pagesCount;
    final List<ConvertedImage> result = [];

    final targetPages = pageNumbers ?? List.generate(total, (i) => i + 1);
    int count = 0;

    for (final p in targetPages) {
      if (p < 1 || p > total) continue;
      final page = await doc.getPage(p);
      final img = await page.render(
        width: page.width * qualityScale,
        height: page.height * qualityScale,
        format: pfx.PdfPageImageFormat.png,
      );
      await page.close();

      if (img != null) {
        result.add(ConvertedImage(
          pageNumber: p,
          bytes: img.bytes,
          format: format,
          fileName: 'page_$p.$format',
        ));
      }

      count++;
      if (onProgress != null) onProgress(count / targetPages.length);
    }

    await doc.close();
    return result;
  }

  /// Converts a collection of images into a multi-page PDF document.
  static Future<Uint8List> imagesToPdf({
    required List<Uint8List> imageBytesList,
    PdfPagePreset pagePreset = PdfPagePreset.a4,
    PdfPageOrientation orientation = PdfPageOrientation.auto,
    PdfImageFit fit = PdfImageFit.contain,
    double margin = 0.0,
    void Function(double progress)? onProgress,
  }) async {
    if (imageBytesList.isEmpty) {
      throw ArgumentError('At least one image is required.');
    }

    final pwDoc = pw.Document();
    int count = 0;

    for (final imgBytes in imageBytesList) {
      final memoryImage = pw.MemoryImage(imgBytes);

      pw_pdf.PdfPageFormat format;
      switch (pagePreset) {
        case PdfPagePreset.letter:
          format = pw_pdf.PdfPageFormat.letter;
          break;
        case PdfPagePreset.a4:
        case PdfPagePreset.fitToImage:
          format = pw_pdf.PdfPageFormat.a4;
          break;
      }

      if (orientation == PdfPageOrientation.landscape) {
        format = format.landscape;
      } else if (orientation == PdfPageOrientation.portrait) {
        format = format.portrait;
      }

      pw.BoxFit boxFit;
      switch (fit) {
        case PdfImageFit.cover:
          boxFit = pw.BoxFit.cover;
          break;
        case PdfImageFit.fill:
          boxFit = pw.BoxFit.fill;
          break;
        case PdfImageFit.contain:
          boxFit = pw.BoxFit.contain;
          break;
      }

      pwDoc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.all(margin),
          build: (_) => pw.Center(
            child: pw.Image(memoryImage, fit: boxFit),
          ),
        ),
      );

      count++;
      if (onProgress != null) onProgress(count / imageBytesList.length);
    }

    return await pwDoc.save();
  }

  /// Converts a PDF to an editable Microsoft Word document (.docx OpenXML archive).
  static Future<Uint8List> pdfToWordDocx({
    required Uint8List pdfBytes,
    void Function(double progress)? onProgress,
  }) async {
    final extractedPages = await extractDecryptedPagesFromPdf(
      pdfBytes: pdfBytes,
      onProgress: (p) {
        if (onProgress != null) onProgress(p * 0.4);
      },
    );

    final total = extractedPages.isNotEmpty ? extractedPages.length : 1;

    // Build OpenXML document.xml
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
    buffer.write('<w:body>');

    for (int i = 0; i < total; i++) {
      final pageText = (i < extractedPages.length) ? extractedPages[i] : '';
      final lines = pageText.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      if (i > 0) {
        // Page break between PDF pages
        buffer.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }

      if (lines.isEmpty) {
        buffer.write('<w:p>');
        buffer.write('<w:pPr><w:spacing w:after="160" w:line="276" w:lineRule="auto"/></w:pPr>');
        buffer.write('<w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve">Page ${i + 1} document content</w:t></w:r>');
        buffer.write('</w:p>');
      } else {
        final paragraphs = _groupLinesIntoParagraphs(lines);

        for (final p in paragraphs) {
          final sanitized = _escapeXml(p.text);
          if (sanitized.isEmpty) continue;

          buffer.write('<w:p>');
          if (p.isHeading1) {
            buffer.write('<w:pPr><w:pStyle w:val="Heading1"/><w:spacing w:before="240" w:after="120"/></w:pPr>');
            buffer.write('<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="32"/><w:color w:val="1F497D"/></w:rPr><w:t xml:space="preserve">$sanitized</w:t></w:r>');
          } else if (p.isHeading2) {
            buffer.write('<w:pPr><w:pStyle w:val="Heading2"/><w:spacing w:before="180" w:after="80"/></w:pPr>');
            buffer.write('<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="26"/><w:color w:val="2E75B6"/></w:rPr><w:t xml:space="preserve">$sanitized</w:t></w:r>');
          } else {
            buffer.write('<w:pPr><w:spacing w:after="160" w:line="276" w:lineRule="auto"/></w:pPr>');
            buffer.write('<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve">$sanitized</w:t></w:r>');
          }
          buffer.write('</w:p>');
        }
      }

      if (onProgress != null) onProgress(0.4 + (((i + 1) / total) * 0.5));
    }

    buffer.write('<w:sectPr>');
    buffer.write('<w:pgSz w:w="11906" w:h="16838"/>');
    buffer.write('<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>');
    buffer.write('</w:sectPr>');
    buffer.write('</w:body></w:document>');

    final archive = Archive();

    // [Content_Types].xml
    archive.addFile(ArchiveFile(
      '[Content_Types].xml',
      utf8.encode(_docxContentTypes).length,
      utf8.encode(_docxContentTypes),
    ));

    // _rels/.rels
    archive.addFile(ArchiveFile(
      '_rels/.rels',
      utf8.encode(_docxRootRels).length,
      utf8.encode(_docxRootRels),
    ));

    // word/_rels/document.xml.rels
    archive.addFile(ArchiveFile(
      'word/_rels/document.xml.rels',
      utf8.encode(_docxDocumentRels).length,
      utf8.encode(_docxDocumentRels),
    ));

    // word/styles.xml
    archive.addFile(ArchiveFile(
      'word/styles.xml',
      utf8.encode(_docxStyles).length,
      utf8.encode(_docxStyles),
    ));

    // word/settings.xml
    archive.addFile(ArchiveFile(
      'word/settings.xml',
      utf8.encode(_docxSettings).length,
      utf8.encode(_docxSettings),
    ));

    // word/fontTable.xml
    archive.addFile(ArchiveFile(
      'word/fontTable.xml',
      utf8.encode(_docxFontTable).length,
      utf8.encode(_docxFontTable),
    ));

    // word/document.xml
    final docBytes = utf8.encode(buffer.toString());
    archive.addFile(ArchiveFile('word/document.xml', docBytes.length, docBytes));

    if (onProgress != null) onProgress(1.0);
    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Converts a PDF to an editable Microsoft Excel spreadsheet (.xlsx OpenXML archive).
  static Future<Uint8List> pdfToExcelXlsx({
    required Uint8List pdfBytes,
    void Function(double progress)? onProgress,
  }) async {
    final extractedPages = await extractDecryptedPagesFromPdf(
      pdfBytes: pdfBytes,
      onProgress: (p) {
        if (onProgress != null) onProgress(p * 0.4);
      },
    );
    final total = extractedPages.isNotEmpty ? extractedPages.length : 1;
    final List<List<String>> tableRows = [];

    // Header row
    tableRows.add(['Page', 'Line #', 'Content / Cell Data']);

    for (int p = 0; p < total; p++) {
      final pageNum = p + 1;
      final rawText = (p < extractedPages.length) ? extractedPages[p] : '';
      final lines = rawText.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      int lineNum = 1;
      for (final line in lines) {
        tableRows.add(['Page $pageNum', '$lineNum', line]);
        lineNum++;
      }
      if (lines.isEmpty) {
        tableRows.add(['Page $pageNum', '1', 'Page $pageNum data record']);
      }
      if (onProgress != null) onProgress(0.4 + ((pageNum / total) * 0.5));
    }

    // Build sheet1.xml
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.write('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    buffer.write('<sheetData>');

    for (int r = 0; r < tableRows.length; r++) {
      final rowNum = r + 1;
      buffer.write('<row r="$rowNum">');
      final cols = tableRows[r];
      for (int c = 0; c < cols.length; c++) {
        final colLetter = String.fromCharCode(65 + c);
        final cellRef = '$colLetter$rowNum';
        final val = _escapeXml(cols[c]);
        buffer.write('<c r="$cellRef" t="inlineStr"><is><t>$val</t></is></c>');
      }
      buffer.write('</row>');
    }

    buffer.write('</sheetData></worksheet>');

    final archive = Archive();
    archive.addFile(ArchiveFile('[Content_Types].xml', utf8.encode(_xlsxContentTypes).length, utf8.encode(_xlsxContentTypes)));
    archive.addFile(ArchiveFile('_rels/.rels', utf8.encode(_xlsxRootRels).length, utf8.encode(_xlsxRootRels)));
    archive.addFile(ArchiveFile('xl/_rels/workbook.xml.rels', utf8.encode(_xlsxWorkbookRels).length, utf8.encode(_xlsxWorkbookRels)));
    archive.addFile(ArchiveFile('xl/workbook.xml', utf8.encode(_xlsxWorkbookXml).length, utf8.encode(_xlsxWorkbookXml)));

    final sheetBytes = utf8.encode(buffer.toString());
    archive.addFile(ArchiveFile('xl/worksheets/sheet1.xml', sheetBytes.length, sheetBytes));

    if (onProgress != null) onProgress(1.0);
    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Converts a PDF to a PowerPoint presentation (.pptx OpenXML archive).
  static Future<Uint8List> pdfToPowerPointPptx({
    required Uint8List pdfBytes,
    void Function(double progress)? onProgress,
  }) async {
    final extractedPages = await extractDecryptedPagesFromPdf(
      pdfBytes: pdfBytes,
      onProgress: (p) {
        if (onProgress != null) onProgress(p * 0.4);
      },
    );
    final total = extractedPages.isNotEmpty ? extractedPages.length : 1;
    final archive = Archive();

    final List<String> slideRelsList = [];

    for (int p = 0; p < total; p++) {
      final pageNum = p + 1;
      final rawText = (p < extractedPages.length) ? extractedPages[p] : '';
      final cleanText = _escapeXml(rawText.isNotEmpty ? rawText : 'Slide $pageNum presentation content');

      final slideXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr/>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="Title $pageNum"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>
        <p:spPr><a:xfrm><a:off x="457200" y="274320"/><a:ext cx="8229600" cy="1143000"/></a:xfrm></p:spPr>
        <p:txBody><a:bodyPr/><a:p><a:r><a:t>Page $pageNum - ReadNext Presentation</a:t></a:r></a:p></p:txBody>
      </p:sp>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="3" name="Content $pageNum"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>
        <p:spPr><a:xfrm><a:off x="457200" y="1600200"/><a:ext cx="8229600" cy="4525963"/></a:xfrm></p:spPr>
        <p:txBody><a:bodyPr/><a:p><a:r><a:t>$cleanText</a:t></a:r></a:p></p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>''';

      final slideBytes = utf8.encode(slideXml);
      archive.addFile(ArchiveFile('ppt/slides/slide$pageNum.xml', slideBytes.length, slideBytes));

      final slideRelXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';
      final relBytes = utf8.encode(slideRelXml);
      archive.addFile(ArchiveFile('ppt/slides/_rels/slide$pageNum.xml.rels', relBytes.length, relBytes));

      slideRelsList.add('<p:sldId id="${255 + pageNum}" r:id="rId${pageNum + 1}"/>');
      if (onProgress != null) onProgress((pageNum / total) * 0.8);
    }

    // Presentation XML
    final presXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
  <p:sldIdLst>
    ${slideRelsList.join('\n    ')}
  </p:sldIdLst>
  <p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>
</p:presentation>''';
    archive.addFile(ArchiveFile('ppt/presentation.xml', utf8.encode(presXml).length, utf8.encode(presXml)));

    // Presentation Rels
    final presRelsBuf = StringBuffer();
    presRelsBuf.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    presRelsBuf.write('<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>\n');
    for (int p = 1; p <= total; p++) {
      presRelsBuf.write('<Relationship Id="rId${p + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$p.xml"/>\n');
    }
    presRelsBuf.write('</Relationships>');
    archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', utf8.encode(presRelsBuf.toString()).length, utf8.encode(presRelsBuf.toString())));

    // [Content_Types].xml
    final ctBuf = StringBuffer();
    ctBuf.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n');
    ctBuf.write('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n');
    ctBuf.write('<Default Extension="xml" ContentType="application/xml"/>\n');
    ctBuf.write('<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>\n');
    for (int p = 1; p <= total; p++) {
      ctBuf.write('<Override PartName="/ppt/slides/slide$p.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>\n');
    }
    ctBuf.write('</Types>');
    archive.addFile(ArchiveFile('[Content_Types].xml', utf8.encode(ctBuf.toString()).length, utf8.encode(ctBuf.toString())));
    archive.addFile(ArchiveFile('_rels/.rels', utf8.encode(_pptxRootRels).length, utf8.encode(_pptxRootRels)));

    if (onProgress != null) onProgress(1.0);
    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  // --- Helper text stream extraction with CMap, encryption detection & decrypted fallback ---

  /// Checks whether a PDF file contains an /Encrypt dictionary (meaning standard PDF encryption).
  /// In encrypted PDFs, raw stream bytes are encrypted ciphertext, so stream extraction
  /// must be bypassed in favor of native PDFium decrypted rendering + OCR.
  static bool isPdfEncrypted(Uint8List bytes) {
    if (bytes.length < 32) return false;
    final trailerLen = bytes.length < 8192 ? bytes.length : 8192;
    final trailerStr = String.fromCharCodes(bytes.sublist(bytes.length - trailerLen));
    if (trailerStr.contains('/Encrypt')) return true;
    final headerStr = String.fromCharCodes(bytes.take(trailerLen));
    if (headerStr.contains('/Encrypt')) return true;
    return false;
  }

  /// Verifies whether text extracted from a PDF stream represents readable language
  /// or un-decrypted ciphertext, random glyphs, or unmapped binary noise.
  static bool isCleanReadableText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 10) {
      return !trimmed.codeUnits.any((c) => (c < 32 && c != 9 && c != 10 && c != 13) || (c >= 127 && c <= 159));
    }

    int total = trimmed.length;
    int unprintableOrControl = 0;
    int letterOrDigit = 0;
    int whitespace = 0;
    int commonPunctuation = 0;

    for (int i = 0; i < total; i++) {
      final code = trimmed.codeUnitAt(i);
      if ((code < 32 && code != 9 && code != 10 && code != 13) ||
          (code >= 127 && code <= 159) ||
          code == 0xFFFD ||
          (code >= 0xE000 && code <= 0xF8FF)) {
        unprintableOrControl++;
      } else {
        final char = trimmed[i];
        if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(char)) {
          letterOrDigit++;
        } else if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
          whitespace++;
        } else if (".,;:!?'\"()[]{}<>-/–—@#\$%&*+=_/\\".contains(char)) {
          commonPunctuation++;
        }
      }
    }

    // Corrupted / un-decrypted if more than 3% unprintable or control chars
    if (unprintableOrControl / total > 0.03) return false;

    // Readable text is composed of letters, digits, spaces, and standard punctuation (at least 70%)
    final readableTotal = letterOrDigit + whitespace + commonPunctuation;
    if (readableTotal / total < 0.70) return false;

    // Must contain letters/digits (at least 20% of content)
    if (letterOrDigit / total < 0.20) return false;

    return true;
  }

  /// Strips unprintable control codes and replacement symbols from text.
  static String sanitizeTextToReadable(String text) {
    if (text.isEmpty) return '';
    final sb = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if ((code >= 32 && code <= 126) ||
          code == 10 || code == 13 || code == 9 ||
          (code >= 160 && code < 0xE000) ||
          (code > 0xF8FF && code < 0xFFFD)) {
        sb.write(text[i]);
      }
    }
    return sb.toString().replaceAll(RegExp(r'[^\S\r\n]{3,}'), ' ').trim();
  }

  /// Extracts clean, decrypted pages from a PDF.
  /// If the PDF is encrypted, has subset font glyphs, or produces garbled text,
  /// it seamlessly falls back to decrypted PDFium rendering and offline neural OCR.
  static Future<List<String>> extractDecryptedPagesFromPdf({
    required Uint8List pdfBytes,
    void Function(double progress)? onProgress,
  }) async {
    final encrypted = isPdfEncrypted(pdfBytes);

    if (!encrypted) {
      try {
        final streamPages = extractPagesFromPdfBytes(pdfBytes);
        if (streamPages.isNotEmpty &&
            streamPages.every((p) => p.trim().isEmpty || isCleanReadableText(p)) &&
            streamPages.any((p) => p.trim().length >= 10 && isCleanReadableText(p))) {
          if (onProgress != null) onProgress(0.5);
          return streamPages;
        }
      } catch (_) {}
    }

    // Decrypted extraction via native PDFium rendering + OCR
    try {
      final ocrResults = await OcrService.performOcr(
        inputBytes: pdfBytes,
        onProgress: onProgress,
      );
      if (ocrResults.isNotEmpty) {
        final ocrPages = ocrResults.map((r) => r.lines.join('\n').trim()).toList();
        if (ocrPages.any((p) => p.isNotEmpty && isCleanReadableText(p))) {
          return ocrPages;
        }
      }
    } catch (_) {}

    // Fallback: sanitized stream pages
    final streamPages = extractPagesFromPdfBytes(pdfBytes);
    return streamPages.map((p) => sanitizeTextToReadable(p)).toList();
  }

  static List<String> extractPagesFromPdfBytes(Uint8List bytes) {
    final pageLines = extractPageLinesFromPdfBytes(bytes);
    return pageLines.map((lines) => lines.map((l) => l.text).join('\n')).toList();
  }

  static List<List<PdfTextLine>> extractPageLinesFromPdfBytes(Uint8List bytes) {
    try {
      final streams = _findPdfStreams(bytes);
      if (streams.isEmpty) return [];

      final Map<int, String> cMap = {};
      final List<String> contentStreams = [];

      for (final s in streams) {
        List<int> decomp;
        try {
          decomp = ZLibDecoder().decodeBytes(s);
        } catch (_) {
          decomp = s;
        }
        final str = String.fromCharCodes(decomp);
        if (str.contains('beginbfchar') || str.contains('beginbfrange')) {
          _parseCMap(str, cMap);
        }
        if (str.contains('BT') && str.contains('ET')) {
          contentStreams.add(str);
        }
      }

      final List<List<PdfTextLine>> pages = [];
      for (final cs in contentStreams) {
        final lines = _decodeContentStreamLines(cs, cMap);
        if (lines.isNotEmpty && lines.any((l) => l.text.trim().isNotEmpty)) {
          pages.add(lines);
        }
      }

      return pages;
    } catch (_) {
      return [];
    }
  }

  static List<Uint8List> _findPdfStreams(Uint8List bytes) {
    final List<Uint8List> streams = [];
    int i = 0;
    while (i < bytes.length - 10) {
      if (bytes[i] == 115 &&
          bytes[i + 1] == 116 &&
          bytes[i + 2] == 114 &&
          bytes[i + 3] == 101 &&
          bytes[i + 4] == 97 &&
          bytes[i + 5] == 109) {
        // Inspect preceding ~250 bytes to check if this stream is a binary image, font, or xref table
        final dictStart = (i > 250) ? i - 250 : 0;
        final dictStr = String.fromCharCodes(bytes.sublist(dictStart, i));
        final isBinaryOnly = RegExp(r'/Subtype\s*/Image').hasMatch(dictStr) ||
            dictStr.contains('/DCTDecode') ||
            dictStr.contains('/JPXDecode') ||
            dictStr.contains('/JBIG2Decode') ||
            dictStr.contains('/FontFile') ||
            RegExp(r'/Type\s*/XRef').hasMatch(dictStr) ||
            RegExp(r'/Type\s*/ObjStm').hasMatch(dictStr);

        int streamStart = i + 6;
        if (streamStart < bytes.length && bytes[streamStart] == 13) streamStart++;
        if (streamStart < bytes.length && bytes[streamStart] == 10) streamStart++;

        int j = streamStart;
        while (j < bytes.length - 9) {
          if (bytes[j] == 101 &&
              bytes[j + 1] == 110 &&
              bytes[j + 2] == 100 &&
              bytes[j + 3] == 115 &&
              bytes[j + 4] == 116 &&
              bytes[j + 5] == 114 &&
              bytes[j + 6] == 101 &&
              bytes[j + 7] == 97 &&
              bytes[j + 8] == 109) {
            int streamEnd = j;
            if (streamEnd > streamStart && (bytes[streamEnd - 1] == 10 || bytes[streamEnd - 1] == 13)) {
              streamEnd--;
            }
            if (streamEnd > streamStart && (bytes[streamEnd - 1] == 10 || bytes[streamEnd - 1] == 13)) {
              streamEnd--;
            }
            if (streamEnd > streamStart && !isBinaryOnly) {
              streams.add(bytes.sublist(streamStart, streamEnd));
            }
            i = j + 9;
            break;
          }
          j++;
        }
      }
      i++;
    }
    return streams;
  }

  static void _parseCMap(String cmapStr, Map<int, String> cMap) {
    final bfcharRegex = RegExp(r'<([0-9a-fA-F]+)>\s*<([0-9a-fA-F]+)>');
    for (final m in bfcharRegex.allMatches(cmapStr)) {
      final src = int.tryParse(m.group(1)!, radix: 16);
      final dstHex = m.group(2)!;
      if (src != null) {
        try {
          final codeUnits = <int>[];
          for (int c = 0; c < dstHex.length; c += 4) {
            final end = (c + 4 <= dstHex.length) ? c + 4 : dstHex.length;
            codeUnits.add(int.parse(dstHex.substring(c, end), radix: 16));
          }
          cMap[src] = String.fromCharCodes(codeUnits);
        } catch (_) {}
      }
    }

    final bfrangeRegex = RegExp(r'<([0-9a-fA-F]+)>\s*<([0-9a-fA-F]+)>\s*<([0-9a-fA-F]+)>');
    for (final m in bfrangeRegex.allMatches(cmapStr)) {
      final s1 = int.tryParse(m.group(1)!, radix: 16);
      final s2 = int.tryParse(m.group(2)!, radix: 16);
      final d1 = int.tryParse(m.group(3)!, radix: 16);
      if (s1 != null && s2 != null && d1 != null) {
        for (int cid = s1; cid <= s2; cid++) {
          final target = d1 + (cid - s1);
          cMap[cid] = String.fromCharCode(target);
        }
      }
    }

    final bfrangeArrayRegex = RegExp(r'<([0-9a-fA-F]+)>\s*<([0-9a-fA-F]+)>\s*\[([\s\S]*?)\]');
    for (final m in bfrangeArrayRegex.allMatches(cmapStr)) {
      final s1 = int.tryParse(m.group(1)!, radix: 16);
      final s2 = int.tryParse(m.group(2)!, radix: 16);
      final arrayContent = m.group(3)!;
      final targetMatches = RegExp(r'<([0-9a-fA-F]+)>').allMatches(arrayContent).toList();
      if (s1 != null && s2 != null) {
        for (int idx = 0; idx < targetMatches.length && (s1 + idx) <= s2; idx++) {
          final hex = targetMatches[idx].group(1)!;
          try {
            final codeUnits = <int>[];
            for (int c = 0; c < hex.length; c += 4) {
              final end = (c + 4 <= hex.length) ? c + 4 : hex.length;
              codeUnits.add(int.parse(hex.substring(c, end), radix: 16));
            }
            cMap[s1 + idx] = String.fromCharCodes(codeUnits);
          } catch (_) {}
        }
      }
    }
  }

  static List<_DocxParagraph> _groupLinesIntoParagraphs(List<String> lines) {
    final List<_DocxParagraph> result = [];
    final List<String> currentParagraphLines = [];

    void flushCurrentParagraph() {
      if (currentParagraphLines.isNotEmpty) {
        final text = currentParagraphLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.isNotEmpty) {
          result.add(_DocxParagraph(text: text, isHeading1: false, isHeading2: false));
        }
        currentParagraphLines.clear();
      }
    }

    for (final line in lines) {
      if (_isMainHeading(line)) {
        flushCurrentParagraph();
        result.add(_DocxParagraph(text: line, isHeading1: true, isHeading2: false));
      } else if (_isSubHeading(line)) {
        flushCurrentParagraph();
        result.add(_DocxParagraph(text: line, isHeading1: false, isHeading2: true));
      } else {
        currentParagraphLines.add(line);
        if (line.endsWith('.') || line.endsWith('!') || line.endsWith('?') || line.endsWith(':') || line.contains('|') || line.contains('___')) {
          flushCurrentParagraph();
        }
      }
    }
    flushCurrentParagraph();
    return result;
  }

  static bool _isMainHeading(String line) {
    if (line.isEmpty) return false;
    if (RegExp(r'^\d+\.\s+[A-Z]').hasMatch(line)) return true;
    if (RegExp(r'^(CHAPTER|SECTION|PART|INVOICE|DOCUMENT|EXECUTIVE SUMMARY)\b', caseSensitive: false).hasMatch(line) && line.length < 60) return true;
    if (line.length <= 40 && line == line.toUpperCase() && RegExp(r'[A-Z]').hasMatch(line) && !line.contains(RegExp(r'[$#%]'))) return true;
    return false;
  }

  static bool _isSubHeading(String line) {
    if (line.isEmpty) return false;
    if (RegExp(r'^\d+\.\d+(\.\d+)?\s+[A-Z]').hasMatch(line)) return true;
    if (line.length < 45 && line.endsWith(':') && !line.contains(r'$') && !line.contains('|')) return true;
    return false;
  }

  static String _unescapePdfString(String raw, Map<int, String> cMap) {
    final sb = StringBuffer();
    int i = 0;
    while (i < raw.length) {
      if (raw[i] == '\\' && i + 1 < raw.length) {
        final next = raw[i + 1];
        if (next == '(' || next == ')' || next == '\\') {
          sb.write(next);
          i += 2;
        } else if (next == 'n') {
          sb.write('\n');
          i += 2;
        } else if (next == 'r') {
          sb.write('\r');
          i += 2;
        } else if (next == 't') {
          sb.write('\t');
          i += 2;
        } else if (next == 'b') {
          sb.write('\b');
          i += 2;
        } else if (next == 'f') {
          sb.write('\f');
          i += 2;
        } else if (RegExp(r'[0-7]').hasMatch(next)) {
          int end = i + 2;
          while (end <= i + 4 && end <= raw.length && RegExp(r'^[0-7]+$').hasMatch(raw.substring(i + 1, end))) {
            end++;
          }
          final octStr = raw.substring(i + 1, end - 1);
          final code = int.tryParse(octStr, radix: 8);
          if (code != null) {
            final mapped = cMap[code];
            if (mapped != null) {
              sb.write(mapped);
            } else if ((code >= 32 && code <= 126) || code == 10 || code == 13 || code == 9) {
              sb.write(String.fromCharCode(code));
            }
          }
          i = end - 1;
        } else {
          sb.write(next);
          i += 2;
        }
      } else {
        final code = raw.codeUnitAt(i);
        final mapped = cMap[code];
        if (mapped != null) {
          sb.write(mapped);
        } else if ((code >= 32 && code <= 126) || code == 10 || code == 13 || code == 9 || code >= 160) {
          sb.write(raw[i]);
        }
        i++;
      }
    }
    return sb.toString();
  }

  static String _decodeHexPdfString(String rawHex, Map<int, String> cMap) {
    String hex = rawHex.replaceAll(RegExp(r'\s+'), '');
    if (hex.length.isOdd) hex += '0';

    final sb = StringBuffer();
    if (hex.length >= 4) {
      for (int i = 0; i < hex.length; i += 4) {
        final end = (i + 4 <= hex.length) ? i + 4 : hex.length;
        final cid = int.tryParse(hex.substring(i, end), radix: 16);
        if (cid != null) {
          final mapped = cMap[cid];
          if (mapped != null) {
            sb.write(mapped);
          } else if ((cid >= 32 && cid <= 126) || cid >= 160) {
            sb.write(String.fromCharCode(cid));
          }
        }
      }
      final res = sb.toString();
      if (res.trim().isNotEmpty && isCleanReadableText(res)) return res;
      sb.clear();
    }

    for (int i = 0; i < hex.length; i += 2) {
      final end = (i + 2 <= hex.length) ? i + 2 : hex.length;
      final code = int.tryParse(hex.substring(i, end), radix: 16);
      if (code != null) {
        final mapped = cMap[code];
        if (mapped != null) {
          sb.write(mapped);
        } else if ((code >= 32 && code <= 126) || code == 10 || code == 13 || code == 9 || code >= 160) {
          sb.write(String.fromCharCode(code));
        }
      }
    }
    return sb.toString();
  }

  static String decodeContentStream(String cs, Map<int, String> cMap) {
    final lines = _decodeContentStreamLines(cs, cMap);
    return lines.map((l) => l.text).join('\n');
  }

  static List<PdfTextLine> _decodeContentStreamLines(String cs, Map<int, String> cMap) {
    final pattern = RegExp(
      r'([-\d\.]+)\s+([-\d\.]+)\s+(?:Td|TD)|'
      r'([-\d\.]+)\s+([-\d\.]+)\s+([-\d\.]+)\s+([-\d\.]+)\s+([-\d\.]+)\s+([-\d\.]+)\s+Tm|'
      r'/([^\s/<>\[\]()]+)\s+([-\d\.]+)\s+Tf|'
      r'\[([\s\S]*?)\]\s*TJ|'
      r'\(([\s\S]*?)\)\s*Tj|'
      r'<([0-9a-fA-F]+)>\s*Tj',
    );

    final lines = <PdfTextLine>[];
    List<String> curLine = [];
    double? curY;
    double lastTx = 0.0;
    double lastTy = 0.0;
    double curFontSize = 12.0;
    double lineStartX = 0.0;
    double lineFontSize = 12.0;

    for (final m in pattern.allMatches(cs)) {
      if (m.group(1) != null) {
        lastTx = double.tryParse(m.group(1)!) ?? lastTx;
        lastTy = double.tryParse(m.group(2)!) ?? lastTy;
      } else if (m.group(3) != null) {
        lastTx = double.tryParse(m.group(7)!) ?? lastTx;
        lastTy = double.tryParse(m.group(8)!) ?? lastTy;
      } else if (m.group(9) != null) {
        curFontSize = double.tryParse(m.group(10)!) ?? curFontSize;
      } else if (m.group(11) != null) {
        final tjContent = m.group(11)!;
        final innerMatches = RegExp(r'\(([\s\S]*?)\)|<([0-9a-fA-F]+)>|([-\d]+(?:\.\d+)?)').allMatches(tjContent);
        final sb = StringBuffer();
        for (final im in innerMatches) {
          if (im.group(1) != null) {
            sb.write(_unescapePdfString(im.group(1)!, cMap));
          } else if (im.group(2) != null) {
            sb.write(_decodeHexPdfString(im.group(2)!, cMap));
          } else if (im.group(3) != null) {
            final offset = double.tryParse(im.group(3)!) ?? 0.0;
            if (offset < -120) sb.write(' ');
          }
        }
        final text = sb.toString().trim();
        if (text.isNotEmpty) {
          if (curY != null && (lastTy - curY).abs() > 2.5) {
            if (curLine.isNotEmpty) {
              lines.add(PdfTextLine(
                text: curLine.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
                x: lineStartX,
                y: curY,
                fontSize: lineFontSize,
              ));
            }
            curLine = [text];
            curY = lastTy;
            lineStartX = lastTx;
            lineFontSize = curFontSize;
          } else {
            curLine.add(text);
            curY ??= lastTy;
            lineStartX = (curLine.length == 1) ? lastTx : lineStartX;
            lineFontSize = (curLine.length == 1) ? curFontSize : lineFontSize;
          }
        }
      } else if (m.group(12) != null) {
        final raw = m.group(12)!;
        final text = _unescapePdfString(raw, cMap).trim();
        if (text.isNotEmpty) {
          if (curY != null && (lastTy - curY).abs() > 2.5) {
            if (curLine.isNotEmpty) {
              lines.add(PdfTextLine(
                text: curLine.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
                x: lineStartX,
                y: curY,
                fontSize: lineFontSize,
              ));
            }
            curLine = [text];
            curY = lastTy;
            lineStartX = lastTx;
            lineFontSize = curFontSize;
          } else {
            curLine.add(text);
            curY ??= lastTy;
            lineStartX = (curLine.length == 1) ? lastTx : lineStartX;
            lineFontSize = (curLine.length == 1) ? curFontSize : lineFontSize;
          }
        }
      } else if (m.group(13) != null) {
        final hex = m.group(13)!;
        final text = _decodeHexPdfString(hex, cMap).trim();
        if (text.isNotEmpty) {
          if (curY != null && (lastTy - curY).abs() > 2.5) {
            if (curLine.isNotEmpty) {
              lines.add(PdfTextLine(
                text: curLine.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
                x: lineStartX,
                y: curY,
                fontSize: lineFontSize,
              ));
            }
            curLine = [text];
            curY = lastTy;
            lineStartX = lastTx;
            lineFontSize = curFontSize;
          } else {
            curLine.add(text);
            curY ??= lastTy;
            lineStartX = (curLine.length == 1) ? lastTx : lineStartX;
            lineFontSize = (curLine.length == 1) ? curFontSize : lineFontSize;
          }
        }
      }
    }

    if (curLine.isNotEmpty) {
      lines.add(PdfTextLine(
        text: curLine.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
        x: lineStartX,
        y: curY ?? lastTy,
        fontSize: lineFontSize,
      ));
    }

    return lines;
  }


  static String _escapeXml(String input) {
    final sanitized = sanitizeTextToReadable(input);
    return sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // XML Templates
  static const _docxContentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
</Types>''';

  static const _docxRootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const _docxDocumentRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
</Relationships>''';

  static const _docxStyles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Times New Roman"/>
        <w:sz w:val="22"/>
        <w:szCs w:val="22"/>
        <w:lang w:val="en-US"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="160" w:line="276" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="240" w:after="120"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="32"/>
      <w:szCs w:val="32"/>
      <w:color w:val="1F497D"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="180" w:after="80"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="26"/>
      <w:szCs w:val="26"/>
      <w:color w:val="2E75B6"/>
    </w:rPr>
  </w:style>
</w:styles>''';

  static const _docxSettings = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:defaultTabStop w:val="720"/>
  <w:characterSpacingControl w:val="doNotCompress"/>
</w:settings>''';

  static const _docxFontTable = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:font w:name="Calibri"><w:panose1 w:val="020F0502020204030204"/></w:font>
  <w:font w:name="Arial"><w:panose1 w:val="020B0604020202020204"/></w:font>
  <w:font w:name="Times New Roman"><w:panose1 w:val="02020603050405020304"/></w:font>
</w:fonts>''';

  static const _xlsxContentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''';

  static const _xlsxRootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

  static const _xlsxWorkbookRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''';

  static const _xlsxWorkbookXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Sheet1" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';

  static const _pptxRootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
}

class _DocxParagraph {
  final String text;
  final bool isHeading1;
  final bool isHeading2;

  const _DocxParagraph({
    required this.text,
    required this.isHeading1,
    required this.isHeading2,
  });
}
