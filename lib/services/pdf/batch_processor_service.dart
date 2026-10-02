import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'pdf_compressor_service.dart';
import 'pdf_converter_service.dart';
import 'pdf_watermark_service.dart';
import '../ocr/ocr_service.dart';

enum BatchOperationType {
  compress,
  pdfToImages,
  pdfToWord,
  pdfToExcel,
  pdfToPowerPoint,
  watermark,
  ocr,
}

class BatchItemProgress {
  final String inputPath;
  final String fileName;
  final double progress;
  final String status;
  final String? outputPath;
  final String? error;

  const BatchItemProgress({
    required this.inputPath,
    required this.fileName,
    this.progress = 0.0,
    this.status = 'Queued',
    this.outputPath,
    this.error,
  });

  BatchItemProgress copyWith({
    double? progress,
    String? status,
    String? outputPath,
    String? error,
  }) {
    return BatchItemProgress(
      inputPath: inputPath,
      fileName: fileName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      outputPath: outputPath ?? this.outputPath,
      error: error ?? this.error,
    );
  }
}

class BatchProcessorService {
  /// Executes a batch operation over a list of PDF file paths.
  static Future<List<BatchItemProgress>> processBatch({
    required List<String> filePaths,
    required BatchOperationType operation,
    WatermarkConfig? watermarkConfig,
    CompressionLevel compressionLevel = CompressionLevel.medium,
    OcrLanguage ocrLanguage = OcrLanguage.english,
    String? customOutputDir,
    void Function(int completedIndex, int totalFiles, BatchItemProgress item)? onItemUpdated,
  }) async {
    final List<BatchItemProgress> results = [];
    final outputDir = customOutputDir ?? await _getDefaultOutputDir();

    for (int i = 0; i < filePaths.length; i++) {
      final inputPath = filePaths[i];
      final fileName = p.basename(inputPath);
      var item = BatchItemProgress(inputPath: inputPath, fileName: fileName, status: 'Processing');
      results.add(item);
      onItemUpdated?.call(i, filePaths.length, item);

      try {
        final inputFile = File(inputPath);
        if (!await inputFile.exists()) {
          throw Exception('File does not exist: $inputPath');
        }
        final bytes = await inputFile.readAsBytes();

        String outPath;
        switch (operation) {
          case BatchOperationType.compress:
            final res = await PdfCompressorService.compressPdf(
              originalBytes: bytes,
              level: compressionLevel,
            );
            outPath = p.join(outputDir, '${p.basenameWithoutExtension(fileName)}_compressed.pdf');
            await File(outPath).writeAsBytes(res.compressedBytes);
            break;

          case BatchOperationType.pdfToImages:
            final imgs = await PdfConverterService.pdfToImages(pdfBytes: bytes);
            final baseName = p.basenameWithoutExtension(fileName);
            outPath = p.join(outputDir, '${baseName}_page_1.png');
            for (final img in imgs) {
              final imgPath = p.join(outputDir, '${baseName}_${img.fileName}');
              await File(imgPath).writeAsBytes(img.bytes);
            }
            break;

          case BatchOperationType.pdfToWord:
            final docxBytes = await PdfConverterService.pdfToWordDocx(pdfBytes: bytes);
            outPath = p.join(outputDir, '${p.basenameWithoutExtension(fileName)}.docx');
            await File(outPath).writeAsBytes(docxBytes);
            break;

          case BatchOperationType.pdfToExcel:
            final xlsxBytes = await PdfConverterService.pdfToExcelXlsx(pdfBytes: bytes);
            outPath = p.join(outputDir, '${p.basenameWithoutExtension(fileName)}.xlsx');
            await File(outPath).writeAsBytes(xlsxBytes);
            break;

          case BatchOperationType.pdfToPowerPoint:
            final pptxBytes = await PdfConverterService.pdfToPowerPointPptx(pdfBytes: bytes);
            outPath = p.join(outputDir, '${p.basenameWithoutExtension(fileName)}.pptx');
            await File(outPath).writeAsBytes(pptxBytes);
            break;

          case BatchOperationType.watermark:
            final cfg = watermarkConfig ?? const WatermarkConfig();
            final watermarked = await PdfWatermarkService.applyWatermark(
              pdfBytes: bytes,
              config: cfg,
            );
            outPath = p.join(outputDir, '${p.basenameWithoutExtension(fileName)}_watermarked.pdf');
            await File(outPath).writeAsBytes(watermarked);
            break;

          case BatchOperationType.ocr:
            final ocrRes = await OcrService.performOcr(
              inputBytes: bytes,
              language: ocrLanguage,
            );
            final searchablePdf = await OcrService.createSearchablePdf(
              originalBytes: bytes,
              ocrResults: ocrRes,
            );
            outPath = p.join(outputDir, '${p.basenameWithoutExtension(fileName)}_searchable.pdf');
            await File(outPath).writeAsBytes(searchablePdf);
            break;
        }

        item = item.copyWith(
          progress: 1.0,
          status: 'Completed',
          outputPath: outPath,
        );
        results[i] = item;
        onItemUpdated?.call(i + 1, filePaths.length, item);
      } catch (e) {
        item = item.copyWith(
          progress: 0.0,
          status: 'Failed',
          error: e.toString(),
        );
        results[i] = item;
        onItemUpdated?.call(i + 1, filePaths.length, item);
      }
    }

    return results;
  }

  static Future<String> _getDefaultOutputDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(docsDir.path, 'ReadNext_Output'));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    return outDir.path;
  }
}
