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
    return saveExportFile(
      fileName: fileName,
      bytes: bytes,
      extension: 'pdf',
      mimeType: 'application/pdf',
      dialogTitle: dialogTitle ?? 'Save PDF Document',
    );
  }

  static Future<String?> saveExportFile({
    required String fileName,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
    String? dialogTitle,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      dialogTitle: dialogTitle ?? 'Save File',
      mimeType: mimeType,
      type: FileType.custom,
      allowedExtensions: [extension],
    );

    if (uri == null) return null;

    String? path;
    try {
      if (uri.scheme == 'file') {
        path = uri.toFilePath();
      } else if (uri.path.isNotEmpty) {
        path = uri.path;
      }
    } catch (_) {
      path = uri.toString();
    }

    if (path != null) {
      try {
        final f = File(path);
        if (!await f.exists() || await f.length() == 0) {
          await f.writeAsBytes(bytes);
        }
      } catch (_) {}
    }
    return path;
  }

  static Future<void> openFileOrFolder(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [p.dirname(filePath)]);
      }
    } catch (_) {}
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
