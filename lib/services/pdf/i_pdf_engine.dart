import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/pdf_document_meta.dart';
import '../../data/models/bookmark_model.dart';
import 'pdf_converter_service.dart';

class SearchMatch {
  final int pageNumber;
  final String matchText;
  final String surroundingSnippet;
  final Rect? bounds;

  const SearchMatch({
    required this.pageNumber,
    required this.matchText,
    required this.surroundingSnippet,
    this.bounds,
  });
}

abstract class IPdfEngine {
  Future<void> openFile(String path, {String? password});
  Future<void> openBytes(Uint8List bytes, {String? password, String? documentName});
  Future<void> close();

  int get pageCount;
  PdfDocumentMeta get metadata;

  Future<Size> getPageDimensions(int pageNumber);
  Future<Uint8List?> renderPageThumbnail(int pageNumber, {int width = 200, int height = 300});
  Future<String> extractText(int pageNumber);
  Future<List<PdfTextLine>> extractPageLines(int pageNumber) async => [];
  Future<List<SearchMatch>> search(String query, {bool caseSensitive = false, bool wholeWord = false});
  Future<List<OutlineItemModel>> getOutline();
  
  bool get isOpen;
  String? get currentPath;
  Uint8List? get currentBytes;
}
