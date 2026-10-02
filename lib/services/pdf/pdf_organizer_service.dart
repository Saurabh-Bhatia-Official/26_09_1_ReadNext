import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pfx;

enum SplitMode {
  everyPage,
  pageRanges,
  equalGroups,
  extractPages,
}

class SplitResultItem {
  final String title;
  final Uint8List bytes;
  final int pageCount;

  SplitResultItem({
    required this.title,
    required this.bytes,
    required this.pageCount,
  });
}

class PdfOrganizerService {
  /// Merges multiple PDF files into one combined PDF byte array.
  static Future<Uint8List> mergePdfFiles({
    required List<String> filePaths,
    void Function(double progress)? onProgress,
  }) async {
    final List<Uint8List> byteList = [];
    for (final path in filePaths) {
      final file = File(path);
      if (await file.exists()) {
        byteList.add(await file.readAsBytes());
      }
    }
    return mergePdfs(pdfByteList: byteList, onProgress: onProgress);
  }

  /// Merges multiple PDF Uint8List documents in the specified order.
  static Future<Uint8List> mergePdfs({
    required List<Uint8List> pdfByteList,
    void Function(double progress)? onProgress,
  }) async {
    if (pdfByteList.isEmpty) {
      throw ArgumentError('At least one PDF is required to merge.');
    }

    final pwDoc = pw.Document();
    int totalDocPages = 0;

    // First count total pages across all docs for accurate progress reporting
    final List<pfx.PdfDocument> openedDocs = [];
    for (final bytes in pdfByteList) {
      final doc = await pfx.PdfDocument.openData(bytes);
      openedDocs.add(doc);
      totalDocPages += doc.pagesCount;
    }

    int processedPages = 0;

    for (int docIdx = 0; docIdx < openedDocs.length; docIdx++) {
      final doc = openedDocs[docIdx];
      for (int pageNum = 1; pageNum <= doc.pagesCount; pageNum++) {
        final page = await doc.getPage(pageNum);
        final pageImage = await page.render(
          width: page.width * 2.0,
          height: page.height * 2.0,
          format: pfx.PdfPageImageFormat.png,
        );
        await page.close();

        if (pageImage != null) {
          final imageMemory = pw.MemoryImage(pageImage.bytes);
          final pageFormat = pw_pdf.PdfPageFormat(page.width, page.height);

          pwDoc.addPage(
            pw.Page(
              pageFormat: pageFormat,
              margin: pw.EdgeInsets.zero,
              build: (context) {
                return pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Image(imageMemory, fit: pw.BoxFit.fill),
                );
              },
            ),
          );
        }

        processedPages++;
        if (onProgress != null && totalDocPages > 0) {
          onProgress(processedPages / totalDocPages);
        }
      }
      await doc.close();
    }

    return await pwDoc.save();
  }

  /// Splits a PDF according to the chosen SplitMode.
  static Future<List<SplitResultItem>> splitPdf({
    required Uint8List bytes,
    required SplitMode mode,
    String? pageRanges,
    int? groupSize,
    List<int>? pagesToExtract,
    void Function(double progress)? onProgress,
  }) async {
    final srcDoc = await pfx.PdfDocument.openData(bytes);
    final totalPages = srcDoc.pagesCount;
    final List<SplitResultItem> results = [];

    if (mode == SplitMode.everyPage) {
      for (int p = 1; p <= totalPages; p++) {
        final pwDoc = pw.Document();
        final page = await srcDoc.getPage(p);
        final img = await page.render(
          width: page.width * 2.0,
          height: page.height * 2.0,
          format: pfx.PdfPageImageFormat.png,
        );
        await page.close();

        if (img != null) {
          pwDoc.addPage(
            pw.Page(
              pageFormat: pw_pdf.PdfPageFormat(page.width, page.height),
              margin: pw.EdgeInsets.zero,
              build: (_) => pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pw.MemoryImage(img.bytes), fit: pw.BoxFit.fill),
              ),
            ),
          );
          final splitBytes = await pwDoc.save();
          results.add(SplitResultItem(
            title: 'Page_$p.pdf',
            bytes: splitBytes,
            pageCount: 1,
          ));
        }

        if (onProgress != null) onProgress(p / totalPages);
      }
    } else if (mode == SplitMode.equalGroups) {
      final size = (groupSize != null && groupSize > 0) ? groupSize : 1;
      int currentGroup = 1;

      for (int start = 1; start <= totalPages; start += size) {
        final end = math.min(start + size - 1, totalPages);
        final pwDoc = pw.Document();

        for (int p = start; p <= end; p++) {
          final page = await srcDoc.getPage(p);
          final img = await page.render(
            width: page.width * 2.0,
            height: page.height * 2.0,
            format: pfx.PdfPageImageFormat.png,
          );
          await page.close();

          if (img != null) {
            pwDoc.addPage(
              pw.Page(
                pageFormat: pw_pdf.PdfPageFormat(page.width, page.height),
                margin: pw.EdgeInsets.zero,
                build: (_) => pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Image(pw.MemoryImage(img.bytes), fit: pw.BoxFit.fill),
                ),
              ),
            );
          }
        }

        final splitBytes = await pwDoc.save();
        results.add(SplitResultItem(
          title: 'Part_${currentGroup}_pages_${start}_to_$end.pdf',
          bytes: splitBytes,
          pageCount: end - start + 1,
        ));
        currentGroup++;

        if (onProgress != null) onProgress(end / totalPages);
      }
    } else if (mode == SplitMode.pageRanges && pageRanges != null) {
      final ranges = parsePageRangeString(pageRanges, totalPages);
      int part = 1;

      for (final rangeList in ranges) {
        if (rangeList.isEmpty) continue;
        final pwDoc = pw.Document();

        for (final p in rangeList) {
          final page = await srcDoc.getPage(p);
          final img = await page.render(
            width: page.width * 2.0,
            height: page.height * 2.0,
            format: pfx.PdfPageImageFormat.png,
          );
          await page.close();

          if (img != null) {
            pwDoc.addPage(
              pw.Page(
                pageFormat: pw_pdf.PdfPageFormat(page.width, page.height),
                margin: pw.EdgeInsets.zero,
                build: (_) => pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Image(pw.MemoryImage(img.bytes), fit: pw.BoxFit.fill),
                ),
              ),
            );
          }
        }

        final splitBytes = await pwDoc.save();
        results.add(SplitResultItem(
          title: 'Range_${part}_(pages_${rangeList.first}-${rangeList.last}).pdf',
          bytes: splitBytes,
          pageCount: rangeList.length,
        ));
        part++;
      }
      if (onProgress != null) onProgress(1.0);
    } else if (mode == SplitMode.extractPages && pagesToExtract != null && pagesToExtract.isNotEmpty) {
      final pwDoc = pw.Document();
      for (final p in pagesToExtract) {
        if (p < 1 || p > totalPages) continue;
        final page = await srcDoc.getPage(p);
        final img = await page.render(
          width: page.width * 2.0,
          height: page.height * 2.0,
          format: pfx.PdfPageImageFormat.png,
        );
        await page.close();

        if (img != null) {
          pwDoc.addPage(
            pw.Page(
              pageFormat: pw_pdf.PdfPageFormat(page.width, page.height),
              margin: pw.EdgeInsets.zero,
              build: (_) => pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pw.MemoryImage(img.bytes), fit: pw.BoxFit.fill),
              ),
            ),
          );
        }
      }

      final splitBytes = await pwDoc.save();
      results.add(SplitResultItem(
        title: 'Extracted_Pages.pdf',
        bytes: splitBytes,
        pageCount: pagesToExtract.length,
      ));
      if (onProgress != null) onProgress(1.0);
    }

    await srcDoc.close();
    return results;
  }

  /// Rotates pages by the specified angle (e.g. 90, 180, 270)
  static Future<Uint8List> rotatePdf({
    required Uint8List bytes,
    required int rotationDegrees,
    List<int>? targetPages,
    void Function(double progress)? onProgress,
  }) async {
    final srcDoc = await pfx.PdfDocument.openData(bytes);
    final totalPages = srcDoc.pagesCount;
    final pwDoc = pw.Document();

    final rad = (rotationDegrees % 360) * (math.pi / 180.0);
    final is90or270 = (rotationDegrees % 180) != 0;

    for (int p = 1; p <= totalPages; p++) {
      final page = await srcDoc.getPage(p);
      final img = await page.render(
        width: page.width * 2.0,
        height: page.height * 2.0,
        format: pfx.PdfPageImageFormat.png,
      );
      await page.close();

      final shouldRotate = targetPages == null || targetPages.contains(p);

      if (img != null) {
        final format = (shouldRotate && is90or270)
            ? pw_pdf.PdfPageFormat(page.height, page.width)
            : pw_pdf.PdfPageFormat(page.width, page.height);

        pwDoc.addPage(
          pw.Page(
            pageFormat: format,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              final imgWidget = pw.Image(pw.MemoryImage(img.bytes), fit: pw.BoxFit.fill);
              if (!shouldRotate || rotationDegrees == 0) {
                return pw.FullPage(ignoreMargins: true, child: imgWidget);
              }
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Center(
                  child: pw.Transform.rotateBox(
                    angle: rad,
                    child: imgWidget,
                  ),
                ),
              );
            },
          ),
        );
      }

      if (onProgress != null) onProgress(p / totalPages);
    }

    await srcDoc.close();
    return await pwDoc.save();
  }

  /// Rearranges pages according to newPageOrder (1-indexed page list, e.g. [3, 1, 2]).
  static Future<Uint8List> reorderPages({
    required Uint8List bytes,
    required List<int> newPageOrder,
    void Function(double progress)? onProgress,
  }) async {
    final srcDoc = await pfx.PdfDocument.openData(bytes);
    final totalPages = srcDoc.pagesCount;
    final pwDoc = pw.Document();

    int count = 0;
    for (final p in newPageOrder) {
      if (p < 1 || p > totalPages) continue;
      final page = await srcDoc.getPage(p);
      final img = await page.render(
        width: page.width * 2.0,
        height: page.height * 2.0,
        format: pfx.PdfPageImageFormat.png,
      );
      await page.close();

      if (img != null) {
        pwDoc.addPage(
          pw.Page(
            pageFormat: pw_pdf.PdfPageFormat(page.width, page.height),
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pw.MemoryImage(img.bytes), fit: pw.BoxFit.fill),
            ),
          ),
        );
      }

      count++;
      if (onProgress != null) onProgress(count / newPageOrder.length);
    }

    await srcDoc.close();
    return await pwDoc.save();
  }

  /// Deletes specific pages from the PDF (1-indexed).
  static Future<Uint8List> deletePages({
    required Uint8List bytes,
    required List<int> pagesToDelete,
    void Function(double progress)? onProgress,
  }) async {
    final srcDoc = await pfx.PdfDocument.openData(bytes);
    final totalPages = srcDoc.pagesCount;
    await srcDoc.close();

    final keepPages = <int>[];
    for (int p = 1; p <= totalPages; p++) {
      if (!pagesToDelete.contains(p)) {
        keepPages.add(p);
      }
    }

    return reorderPages(bytes: bytes, newPageOrder: keepPages, onProgress: onProgress);
  }

  /// Extracts specified pages into a new PDF (1-indexed).
  static Future<Uint8List> extractPages({
    required Uint8List bytes,
    required List<int> pagesToExtract,
    void Function(double progress)? onProgress,
  }) async {
    return reorderPages(bytes: bytes, newPageOrder: pagesToExtract, onProgress: onProgress);
  }

  /// Reverses the page order of a PDF.
  static Future<Uint8List> reversePages({
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final srcDoc = await pfx.PdfDocument.openData(bytes);
    final totalPages = srcDoc.pagesCount;
    await srcDoc.close();

    final reversed = List.generate(totalPages, (i) => totalPages - i);
    return reorderPages(bytes: bytes, newPageOrder: reversed, onProgress: onProgress);
  }

  /// Helper to parse range strings such as "1-3, 5, 7-10"
  static List<List<int>> parsePageRangeString(String input, int maxPages) {
    final List<List<int>> result = [];
    final parts = input.split(RegExp(r'[,;]'));

    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;

      if (part.contains('-')) {
        final sub = part.split('-');
        if (sub.length == 2) {
          final start = int.tryParse(sub[0].trim());
          final end = int.tryParse(sub[1].trim());
          if (start != null && end != null) {
            final realStart = start.clamp(1, maxPages);
            final realEnd = end.clamp(1, maxPages);
            if (realStart <= realEnd) {
              result.add(List.generate(realEnd - realStart + 1, (i) => realStart + i));
            }
          }
        }
      } else {
        final single = int.tryParse(part);
        if (single != null && single >= 1 && single <= maxPages) {
          result.add([single]);
        }
      }
    }

    return result;
  }
}
