import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class FileService {
  static Future<String?> pickPdfFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return file?.path;
  }

  static Future<List<String>> pickMultiplePdfFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return files.map((f) => f.path).whereType<String>().toList();
  }

  static Future<List<String>> pickMultipleImageFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'tiff'],
    );
    return files.map((f) => f.path).whereType<String>().toList();
  }

  static Future<String?> pickSingleImageFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    return file?.path;
  }

  static Future<String?> pickDocumentOrImageFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'tiff'],
    );
    return file?.path;
  }

  static Future<String?> savePdfFile({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      dialogTitle: dialogTitle ?? 'Save PDF Document',
      mimeType: 'application/pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return uri?.toFilePath();
  }

  static Future<Uint8List> loadSamplePdf() async {
    final byteData = await rootBundle.load('assets/sample.pdf');
    return byteData.buffer.asUint8List();
  }

  static String getFileName(String path) {
    return p.basename(path);
  }

  static int getFileSize(String path) {
    try {
      final file = File(path);
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }
}
