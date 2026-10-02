import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pfx;
import '../../data/models/pdf_document_meta.dart';
import '../../data/models/bookmark_model.dart';
import 'i_pdf_engine.dart';
import 'pdf_converter_service.dart';

class PdfxEngineImpl implements IPdfEngine {
  pfx.PdfDocument? _document;
  String? _currentPath;
  Uint8List? _currentBytes;
  PdfDocumentMeta _metadata = PdfDocumentMeta.empty();
  final Map<int, String> _extractedTextCache = {};
  final Map<int, List<PdfTextLine>> _extractedLinesCache = {};
  final Map<int, Size> _dimensionsCache = {};

  @override
  bool get isOpen => _document != null;

  @override
  String? get currentPath => _currentPath;

  @override
  Uint8List? get currentBytes => _currentBytes;

  @override
  int get pageCount => _document?.pagesCount ?? 0;

  @override
  PdfDocumentMeta get metadata => _metadata;

  @override
  Future<void> openFile(String path, {String? password}) async {
    await close();
    final file = File(path);
    final bytes = await file.readAsBytes();
    _currentPath = path;
    _currentBytes = bytes;

    _document = await pfx.PdfDocument.openFile(path, password: password);

    final fileName = path.split(Platform.pathSeparator).last;
    _metadata = PdfDocumentMeta(
      title: fileName,
      filePath: path,
      fileSize: bytes.length,
      pageCount: _document!.pagesCount,
      modificationDate: file.lastModifiedSync(),
    );

    await _indexDocumentText();
  }

  @override
  Future<void> openBytes(Uint8List bytes, {String? password, String? documentName}) async {
    await close();
    _currentPath = null;
    _currentBytes = bytes;

    _document = await pfx.PdfDocument.openData(bytes, password: password);

    _metadata = PdfDocumentMeta(
      title: documentName ?? 'Document.pdf',
      filePath: '',
      fileSize: bytes.length,
      pageCount: _document!.pagesCount,
      modificationDate: DateTime.now(),
    );

    await _indexDocumentText();
  }

  @override
  Future<void> close() async {
    if (_document != null) {
      await _document!.close();
      _document = null;
    }
    _currentPath = null;
    _currentBytes = null;
    _metadata = PdfDocumentMeta.empty();
    _extractedTextCache.clear();
    _extractedLinesCache.clear();
    _dimensionsCache.clear();
  }

  @override
  Future<Size> getPageDimensions(int pageNumber) async {
    if (_document == null || pageNumber < 1 || pageNumber > pageCount) {
      return const Size(595, 842); // Default A4
    }
    if (_dimensionsCache.containsKey(pageNumber)) {
      return _dimensionsCache[pageNumber]!;
    }

    try {
      final page = await _document!.getPage(pageNumber);
      final size = Size(page.width, page.height);
      await page.close();
      _dimensionsCache[pageNumber] = size;
      return size;
    } catch (e) {
      return const Size(595, 842);
    }
  }

  @override
  Future<Uint8List?> renderPageThumbnail(int pageNumber, {int width = 200, int height = 300}) async {
    if (_document == null || pageNumber < 1 || pageNumber > pageCount) return null;
    try {
      final page = await _document!.getPage(pageNumber);
      final pageImage = await page.render(
        width: width.toDouble(),
        height: height.toDouble(),
        format: pfx.PdfPageImageFormat.png,
      );
      await page.close();
      return pageImage?.bytes;
    } catch (e) {
      debugPrint('Error rendering thumbnail: $e');
      return null;
    }
  }

  @override
  Future<String> extractText(int pageNumber) async {
    return _extractedTextCache[pageNumber] ?? '';
  }

  @override
  Future<List<PdfTextLine>> extractPageLines(int pageNumber) async {
    return _extractedLinesCache[pageNumber] ?? [];
  }

  @override
  Future<List<SearchMatch>> search(String query, {bool caseSensitive = false, bool wholeWord = false}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _document == null) return [];

    final List<SearchMatch> matches = [];
    final pattern = wholeWord ? '\\b${RegExp.escape(cleanQuery)}\\b' : RegExp.escape(cleanQuery);
    final regExp = RegExp(pattern, caseSensitive: caseSensitive);

    for (int page = 1; page <= pageCount; page++) {
      final text = _extractedTextCache[page] ?? '';
      final matchIter = regExp.allMatches(text);

      for (final match in matchIter) {
        final start = (match.start - 25).clamp(0, text.length);
        final end = (match.end + 25).clamp(0, text.length);
        final snippet = '...${text.substring(start, end).replaceAll('\n', ' ')}...';

        matches.add(
          SearchMatch(
            pageNumber: page,
            matchText: match.group(0) ?? cleanQuery,
            surroundingSnippet: snippet,
          ),
        );
      }
    }

    return matches;
  }

  @override
  Future<List<OutlineItemModel>> getOutline() async {
    // Generate document outline based on pages
    final List<OutlineItemModel> items = [];
    for (int i = 1; i <= pageCount; i++) {
      final title = _extractedTextCache[i]?.split('\n').firstWhere(
                (line) => line.trim().isNotEmpty,
                orElse: () => 'Page $i',
              ) ??
          'Page $i';

      items.add(OutlineItemModel(
        title: title.length > 35 ? '${title.substring(0, 35)}...' : title,
        pageNumber: i,
      ));
    }
    return items;
  }

  // Parses textual content out of PDF bytes streams for instant search
  Future<void> _indexDocumentText() async {
    if (_currentBytes == null) return;
    try {
      final isEnc = PdfConverterService.isPdfEncrypted(_currentBytes!);
      List<List<PdfTextLine>> pageLines = [];
      if (!isEnc) {
        pageLines = PdfConverterService.extractPageLinesFromPdfBytes(_currentBytes!);
      }

      final bool hasCleanText = pageLines.isNotEmpty && pageLines.any((lines) =>
          lines.isNotEmpty && PdfConverterService.isCleanReadableText(lines.map((l) => l.text).join(' ')));

      if (hasCleanText) {
        for (int i = 1; i <= pageCount; i++) {
          if (i - 1 < pageLines.length && pageLines[i - 1].isNotEmpty) {
            final sorted = List<PdfTextLine>.from(pageLines[i - 1]);
            sorted.sort((a, b) => b.y.compareTo(a.y));
            _extractedLinesCache[i] = sorted;
            _extractedTextCache[i] = sorted.map((l) => l.text).join('\n').trim();
          } else {
            _extractedLinesCache[i] = [PdfTextLine(text: 'Page $i Content')];
            _extractedTextCache[i] = 'Page $i Content';
          }
        }
      } else {
        // PDF is encrypted or stream text contains unmapped font glyphs/ciphertext.
        // Fallback to decrypted extraction asynchronously so initial UI remains responsive.
        for (int i = 1; i <= pageCount; i++) {
          _extractedLinesCache[i] = [PdfTextLine(text: 'Page $i Content')];
          _extractedTextCache[i] = 'Page $i Content';
        }

        PdfConverterService.extractDecryptedPagesFromPdf(pdfBytes: _currentBytes!).then((decPages) {
          for (int i = 1; i <= pageCount; i++) {
            if (i - 1 < decPages.length && decPages[i - 1].isNotEmpty) {
              final text = decPages[i - 1].trim();
              final lines = text.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              final lineObjects = <PdfTextLine>[];
              double curY = 800.0;
              for (final l in lines) {
                lineObjects.add(PdfTextLine(text: l, x: 40.0, y: curY, fontSize: 12.0));
                curY -= 20.0;
              }
              _extractedLinesCache[i] = lineObjects;
              _extractedTextCache[i] = text;
            }
          }
        }).catchError((_) {});
      }
    } catch (e) {
      for (int i = 1; i <= pageCount; i++) {
        _extractedLinesCache[i] = [PdfTextLine(text: 'Page $i')];
        _extractedTextCache[i] = 'Page $i';
      }
    }
  }
}
