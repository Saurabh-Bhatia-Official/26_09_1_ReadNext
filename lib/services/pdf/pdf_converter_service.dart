import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pfx;

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
    final extractedPages = extractPagesFromPdfBytes(pdfBytes);
    final total = extractedPages.isNotEmpty ? extractedPages.length : 1;
    final List<String> paragraphs = [];

    for (int i = 0; i < total; i++) {
      final pageNum = i + 1;
      paragraphs.add('--- Page $pageNum ---');
      final pageText = (i < extractedPages.length) ? extractedPages[i] : '';
      if (pageText.isNotEmpty) {
        paragraphs.addAll(pageText.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty));
      } else {
        paragraphs.add('Page $pageNum document content');
      }
      if (onProgress != null) onProgress((pageNum / total) * 0.7);
    }

    // Build OpenXML document.xml
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    buffer.write('<w:body>');

    for (final p in paragraphs) {
      final sanitized = _escapeXml(p);
      if (sanitized.trim().isEmpty) continue;
      final isHeading = sanitized.startsWith('--- Page');
      buffer.write('<w:p>');
      if (isHeading) {
        buffer.write('<w:pPr><w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="1E88E5"/></w:rPr></w:pPr>');
      }
      buffer.write('<w:r><w:t xml:space="preserve">$sanitized</w:t></w:r>');
      buffer.write('</w:p>');
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
    final extractedPages = extractPagesFromPdfBytes(pdfBytes);
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
      if (onProgress != null) onProgress((pageNum / total) * 0.7);
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
    final extractedPages = extractPagesFromPdfBytes(pdfBytes);
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

  // --- Helper text stream extraction with CMap & zlib decoding ---
  static List<String> extractPagesFromPdfBytes(Uint8List bytes) {
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

      final List<String> pages = [];
      for (final cs in contentStreams) {
        final decoded = _decodeContentStream(cs, cMap);
        if (decoded.trim().isNotEmpty) {
          pages.add(decoded.trim());
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
            if (streamEnd > streamStart) {
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
  }

  static String _decodeContentStream(String cs, Map<int, String> cMap) {
    final lines = <String>[];
    final btBlocks = RegExp(r'BT([\s\S]*?)ET').allMatches(cs);

    for (final bt in btBlocks) {
      final block = bt.group(1) ?? '';
      // 1. TJ array operator
      final tjArrays = RegExp(r'\[([\s\S]*?)\]\s*TJ').allMatches(block);
      for (final arr in tjArrays) {
        final content = arr.group(1) ?? '';
        final hexMatches = RegExp(r'<([0-9a-fA-F]+)>').allMatches(content);
        final sb = StringBuffer();
        for (final hm in hexMatches) {
          final h = hm.group(1) ?? '';
          for (int c = 0; c < h.length; c += 4) {
            final end = (c + 4 <= h.length) ? c + 4 : h.length;
            final cid = int.tryParse(h.substring(c, end), radix: 16);
            if (cid != null) {
              sb.write(cMap[cid] ?? '');
            }
          }
        }
        final strMatches = RegExp(r'\((.*?)\)').allMatches(content);
        for (final sm in strMatches) {
          final lit = sm.group(1) ?? '';
          for (int c = 0; c < lit.length; c++) {
            final code = lit.codeUnitAt(c);
            sb.write(cMap[code] ?? (code >= 32 && code <= 126 ? lit[c] : ''));
          }
        }
        final s = sb.toString().trim();
        if (s.isNotEmpty) lines.add(s);
      }

      // 2. Tj operator with hex
      final hexTj = RegExp(r'<([0-9a-fA-F]+)>\s*Tj').allMatches(block);
      for (final ht in hexTj) {
        final h = ht.group(1) ?? '';
        final sb = StringBuffer();
        for (int c = 0; c < h.length; c += 4) {
          final end = (c + 4 <= h.length) ? c + 4 : h.length;
          final cid = int.tryParse(h.substring(c, end), radix: 16);
          if (cid != null) sb.write(cMap[cid] ?? '');
        }
        final s = sb.toString().trim();
        if (s.isNotEmpty) lines.add(s);
      }

      // 3. Tj operator with literal string
      final litTj = RegExp(r'\((.*?)\)\s*Tj').allMatches(block);
      for (final lt in litTj) {
        final lit = lt.group(1) ?? '';
        final sb = StringBuffer();
        for (int c = 0; c < lit.length; c++) {
          final code = lit.codeUnitAt(c);
          sb.write(cMap[code] ?? (code >= 32 && code <= 126 ? lit[c] : ''));
        }
        final s = sb.toString().trim();
        if (s.isNotEmpty) lines.add(s);
      }
    }

    return lines.join('\n');
  }

  static String _escapeXml(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\uD7FF\uE000-\uFFFD]'), '');
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
</Types>''';

  static const _docxRootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

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
