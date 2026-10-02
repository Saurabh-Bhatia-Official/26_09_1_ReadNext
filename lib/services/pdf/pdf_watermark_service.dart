import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pfx;

enum WatermarkType { text, image }

enum WatermarkPosition {
  center,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class WatermarkConfig {
  final WatermarkType type;
  final String text;
  final double fontSize;
  final int colorRgba;
  final double opacity;
  final double rotationDegrees;
  final Uint8List? imageBytes;
  final double imageScale;
  final WatermarkPosition position;
  final List<int>? targetPages; // null = all pages

  const WatermarkConfig({
    this.type = WatermarkType.text,
    this.text = 'CONFIDENTIAL',
    this.fontSize = 46.0,
    this.colorRgba = 0x66FF0000, // Semi-transparent red
    this.opacity = 0.35,
    this.rotationDegrees = -45.0,
    this.imageBytes,
    this.imageScale = 0.5,
    this.position = WatermarkPosition.center,
    this.targetPages,
  });

  WatermarkConfig copyWith({
    WatermarkType? type,
    String? text,
    double? fontSize,
    int? colorRgba,
    double? opacity,
    double? rotationDegrees,
    Uint8List? imageBytes,
    double? imageScale,
    WatermarkPosition? position,
    List<int>? targetPages,
  }) {
    return WatermarkConfig(
      type: type ?? this.type,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      colorRgba: colorRgba ?? this.colorRgba,
      opacity: opacity ?? this.opacity,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      imageBytes: imageBytes ?? this.imageBytes,
      imageScale: imageScale ?? this.imageScale,
      position: position ?? this.position,
      targetPages: targetPages ?? this.targetPages,
    );
  }
}

class PdfWatermarkService {
  /// Applies a customizable text or image watermark to designated pages of a PDF.
  static Future<Uint8List> applyWatermark({
    required Uint8List pdfBytes,
    required WatermarkConfig config,
    void Function(double progress)? onProgress,
  }) async {
    final doc = await pfx.PdfDocument.openData(pdfBytes);
    final total = doc.pagesCount;
    final pwDoc = pw.Document();

    final radians = config.rotationDegrees * (math.pi / 180.0);
    pw.MemoryImage? watermarkImage;
    if (config.type == WatermarkType.image && config.imageBytes != null) {
      watermarkImage = pw.MemoryImage(config.imageBytes!);
    }

    for (int p = 1; p <= total; p++) {
      final page = await doc.getPage(p);
      final pageImg = await page.render(
        width: page.width * 2.0,
        height: page.height * 2.0,
        format: pfx.PdfPageImageFormat.png,
      );
      await page.close();

      final shouldWatermark = config.targetPages == null || config.targetPages!.contains(p);

      if (pageImg != null) {
        final format = pw_pdf.PdfPageFormat(page.width, page.height);
        final baseMemory = pw.MemoryImage(pageImg.bytes);

        pwDoc.addPage(
          pw.Page(
            pageFormat: format,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              return pw.Stack(
                children: [
                  pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Image(baseMemory, fit: pw.BoxFit.fill),
                  ),
                  if (shouldWatermark)
                    pw.FullPage(
                      ignoreMargins: true,
                      child: _buildWatermarkOverlay(config, radians, watermarkImage, page.width, page.height),
                    ),
                ],
              );
            },
          ),
        );
      }

      if (onProgress != null) onProgress(p / total);
    }

    await doc.close();
    return await pwDoc.save();
  }

  static pw.Widget _buildWatermarkOverlay(
    WatermarkConfig config,
    double radians,
    pw.MemoryImage? watermarkImage,
    double pageWidth,
    double pageHeight,
  ) {
    pw.Widget contentWidget;

    if (config.type == WatermarkType.image && watermarkImage != null) {
      contentWidget = pw.Opacity(
        opacity: config.opacity.clamp(0.05, 1.0),
        child: pw.Transform.rotateBox(
          angle: radians,
          child: pw.Image(
            watermarkImage,
            width: (pageWidth * config.imageScale).clamp(50.0, pageWidth),
            fit: pw.BoxFit.contain,
          ),
        ),
      );
    } else {
      contentWidget = pw.Opacity(
        opacity: config.opacity.clamp(0.05, 1.0),
        child: pw.Transform.rotateBox(
          angle: radians,
          child: pw.Text(
            config.text,
            style: pw.TextStyle(
              fontSize: config.fontSize,
              fontWeight: pw.FontWeight.bold,
              color: pw_pdf.PdfColor.fromInt(config.colorRgba),
            ),
          ),
        ),
      );
    }

    pw.Alignment alignment;
    switch (config.position) {
      case WatermarkPosition.topLeft:
        alignment = pw.Alignment.topLeft;
        break;
      case WatermarkPosition.topRight:
        alignment = pw.Alignment.topRight;
        break;
      case WatermarkPosition.bottomLeft:
        alignment = pw.Alignment.bottomLeft;
        break;
      case WatermarkPosition.bottomRight:
        alignment = pw.Alignment.bottomRight;
        break;
      case WatermarkPosition.center:
        alignment = pw.Alignment.center;
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(32),
      alignment: alignment,
      child: contentWidget,
    );
  }
}
