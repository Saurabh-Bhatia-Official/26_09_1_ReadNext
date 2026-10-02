import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart' as pfx;

enum ComparisonDiffType {
  identical,
  modified,
  added,
  removed,
}

class PageDiff {
  final int pageNumber;
  final ComparisonDiffType diffType;
  final String docAText;
  final String docBText;
  final List<String> addedWords;
  final List<String> removedWords;
  final Uint8List? pageAImage;
  final Uint8List? pageBImage;

  const PageDiff({
    required this.pageNumber,
    required this.diffType,
    required this.docAText,
    required this.docBText,
    required this.addedWords,
    required this.removedWords,
    this.pageAImage,
    this.pageBImage,
  });
}

class ComparisonResult {
  final int totalPagesA;
  final int totalPagesB;
  final int identicalCount;
  final int modifiedCount;
  final int addedCount;
  final int removedCount;
  final List<PageDiff> pageDiffs;

  const ComparisonResult({
    required this.totalPagesA,
    required this.totalPagesB,
    required this.identicalCount,
    required this.modifiedCount,
    required this.addedCount,
    required this.removedCount,
    required this.pageDiffs,
  });

  bool get hasDifferences => modifiedCount > 0 || addedCount > 0 || removedCount > 0;
  String get summary => hasDifferences
      ? '$modifiedCount page(s) modified, $addedCount page(s) added, $removedCount page(s) removed'
      : 'Documents are identical';
}

class PdfComparisonService {
  /// Compares two PDF documents and extracts side-by-side visual and textual differences.
  static Future<ComparisonResult> compareDocuments({
    required Uint8List bytesA,
    required Uint8List bytesB,
    void Function(double progress)? onProgress,
  }) async {
    final docA = await pfx.PdfDocument.openData(bytesA);
    final docB = await pfx.PdfDocument.openData(bytesB);

    final totalA = docA.pagesCount;
    final totalB = docB.pagesCount;
    final maxPages = math.max(totalA, totalB);

    final List<PageDiff> diffs = [];
    int identicalCount = 0;
    int modifiedCount = 0;
    int addedCount = 0;
    int removedCount = 0;

    for (int p = 1; p <= maxPages; p++) {
      Uint8List? imgA;
      Uint8List? imgB;
      String textA = '';
      String textB = '';

      if (p <= totalA) {
        final pageA = await docA.getPage(p);
        final renderedA = await pageA.render(width: 300, height: 420, format: pfx.PdfPageImageFormat.png);
        await pageA.close();
        imgA = renderedA?.bytes;
        textA = _extractTextFromPdfStream(bytesA, p, totalA);
      }

      if (p <= totalB) {
        final pageB = await docB.getPage(p);
        final renderedB = await pageB.render(width: 300, height: 420, format: pfx.PdfPageImageFormat.png);
        await pageB.close();
        imgB = renderedB?.bytes;
        textB = _extractTextFromPdfStream(bytesB, p, totalB);
      }

      ComparisonDiffType diffType;
      final List<String> addedWords = [];
      final List<String> removedWords = [];

      if (p > totalA) {
        diffType = ComparisonDiffType.added;
        addedCount++;
        addedWords.addAll(textB.split(RegExp(r'\s+')).where((s) => s.isNotEmpty));
      } else if (p > totalB) {
        diffType = ComparisonDiffType.removed;
        removedCount++;
        removedWords.addAll(textA.split(RegExp(r'\s+')).where((s) => s.isNotEmpty));
      } else {
        final wordsA = textA.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toSet();
        final wordsB = textB.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toSet();

        final added = wordsB.difference(wordsA);
        final removed = wordsA.difference(wordsB);

        if (added.isEmpty && removed.isEmpty && textA.trim() == textB.trim()) {
          diffType = ComparisonDiffType.identical;
          identicalCount++;
        } else {
          diffType = ComparisonDiffType.modified;
          modifiedCount++;
          addedWords.addAll(added);
          removedWords.addAll(removed);
        }
      }

      diffs.add(PageDiff(
        pageNumber: p,
        diffType: diffType,
        docAText: textA,
        docBText: textB,
        addedWords: addedWords,
        removedWords: removedWords,
        pageAImage: imgA,
        pageBImage: imgB,
      ));

      if (onProgress != null) onProgress(p / maxPages);
    }

    await docA.close();
    await docB.close();

    return ComparisonResult(
      totalPagesA: totalA,
      totalPagesB: totalB,
      identicalCount: identicalCount,
      modifiedCount: modifiedCount,
      addedCount: addedCount,
      removedCount: removedCount,
      pageDiffs: diffs,
    );
  }

  static String _extractTextFromPdfStream(Uint8List bytes, int pageNum, int totalPages) {
    try {
      final rawString = String.fromCharCodes(bytes);
      final streamRegex = RegExp(r'stream[\r\n]+([\s\S]*?)[\r\n]+endstream');
      final textRegex = RegExp(r'\((.*?)\)');
      final streams = streamRegex.allMatches(rawString);

      final StringBuffer docText = StringBuffer();
      for (final s in streams) {
        final content = s.group(1) ?? '';
        final matches = textRegex.allMatches(content);
        for (final m in matches) {
          final t = m.group(1);
          if (t != null && t.length > 1 && !t.startsWith('/')) {
            docText.write('$t ');
          }
        }
      }

      final allWords = docText.toString().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (allWords.isEmpty) return 'Page $pageNum content';

      final wordsPerPage = (allWords.length / (totalPages > 0 ? totalPages : 1)).ceil();
      final start = (pageNum - 1) * wordsPerPage;
      final end = (start + wordsPerPage).clamp(0, allWords.length);

      if (start < allWords.length) {
        return allWords.sublist(start, end).join(' ');
      }
      return 'Page $pageNum';
    } catch (_) {
      return '';
    }
  }
}
