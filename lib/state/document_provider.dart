import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/models/pdf_document_meta.dart';
import '../../data/models/recent_document.dart';
import '../../services/file_service.dart';
import '../../services/pdf/i_pdf_engine.dart';
import '../../services/pdf/pdfx_engine_impl.dart';

class DocumentState {
  final bool isLoading;
  final String? error;
  final IPdfEngine engine;
  final PdfDocumentMeta metadata;
  final String? currentPath;
  final Uint8List? currentBytes;
  final bool isPasswordProtected;

  const DocumentState({
    required this.isLoading,
    this.error,
    required this.engine,
    required this.metadata,
    this.currentPath,
    this.currentBytes,
    this.isPasswordProtected = false,
  });

  bool get hasDocument => engine.isOpen;

  DocumentState copyWith({
    bool? isLoading,
    String? error,
    IPdfEngine? engine,
    PdfDocumentMeta? metadata,
    String? currentPath,
    Uint8List? currentBytes,
    bool? isPasswordProtected,
  }) {
    return DocumentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      engine: engine ?? this.engine,
      metadata: metadata ?? this.metadata,
      currentPath: currentPath ?? this.currentPath,
      currentBytes: currentBytes ?? this.currentBytes,
      isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
    );
  }
}

class DocumentNotifier extends Notifier<DocumentState> {
  @override
  DocumentState build() {
    return DocumentState(
      isLoading: false,
      engine: PdfxEngineImpl(),
      metadata: PdfDocumentMeta.empty(),
    );
  }

  Future<void> openFile(String path, {String? password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await state.engine.openFile(path, password: password);
      final meta = state.engine.metadata;

      // Save to recent documents in SQLite
      final recentDoc = RecentDocument(
        id: path,
        path: path,
        title: meta.title,
        pageCount: meta.pageCount,
        lastPage: 1,
        fileSize: meta.fileSize,
        lastOpened: DateTime.now(),
      );
      await AppDatabase.instance.upsertRecentDocument(recentDoc);

      state = state.copyWith(
        isLoading: false,
        currentPath: path,
        currentBytes: state.engine.currentBytes,
        metadata: meta,
        isPasswordProtected: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open document: $e',
      );
    }
  }

  Future<void> openBytes(Uint8List bytes, {String? name, String? password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await state.engine.openBytes(bytes, password: password, documentName: name);
      final meta = state.engine.metadata;

      state = state.copyWith(
        isLoading: false,
        currentPath: null,
        currentBytes: bytes,
        metadata: meta,
        isPasswordProtected: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open document: $e',
      );
    }
  }

  Future<void> openSample() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sampleBytes = await FileService.loadSamplePdf();
      await openBytes(sampleBytes, name: 'Sample_Specification.pdf');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load sample document: $e',
      );
    }
  }

  Future<void> closeDocument() async {
    await state.engine.close();
    state = state.copyWith(
      isLoading: false,
      currentPath: null,
      currentBytes: null,
      metadata: PdfDocumentMeta.empty(),
    );
  }
}

final documentProvider = NotifierProvider<DocumentNotifier, DocumentState>(DocumentNotifier.new);
