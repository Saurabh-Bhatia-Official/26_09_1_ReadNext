import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pfx;
import '../../data/models/annotation_model.dart';

class PdfExportService {
  static Future<Uint8List> exportAnnotatedPdf({
    required Uint8List originalBytes,
    required List<AnnotationModel> annotations,
  }) async {
    final pdfDocument = await pfx.PdfDocument.openData(originalBytes);
    final totalPages = pdfDocument.pagesCount;
    final pwDoc = pw.Document();

    for (int pageNum = 1; pageNum <= totalPages; pageNum++) {
      final page = await pdfDocument.getPage(pageNum);
      // High-res rendering for print & export quality
      final pageImage = await page.render(
        width: page.width * 2.0,
        height: page.height * 2.0,
        format: pfx.PdfPageImageFormat.png,
      );
      await page.close();

      final pageAnnotations = annotations.where((a) => a.pageNumber == pageNum).toList();

      if (pageImage != null) {
        final imageMemory = pw.MemoryImage(pageImage.bytes);
        final format = pw_pdf.PdfPageFormat(page.width, page.height);

        pwDoc.addPage(
          pw.Page(
            pageFormat: format,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              return pw.Stack(
                children: [
                  pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Image(imageMemory, fit: pw.BoxFit.fill),
                  ),
                  // Render overlay annotations
                  ...pageAnnotations.map((anno) {
                    return _buildAnnotationWidget(anno, page.width, page.height);
                  }),
                ],
              );
            },
          ),
        );
      }
    }

    await pdfDocument.close();
    return await pwDoc.save();
  }

  static pw.Widget _buildAnnotationWidget(AnnotationModel anno, double pageWidth, double pageHeight) {
    switch (anno.type) {
      case AnnotationType.highlight:
        return pw.Positioned(
          left: anno.rect.left,
          top: anno.rect.top,
          child: pw.Opacity(
            opacity: 0.45,
            child: pw.Container(
              width: anno.rect.width,
              height: anno.rect.height,
              color: pw_pdf.PdfColor.fromInt(anno.color.toARGB32()),
            ),
          ),
        );

      case AnnotationType.underline:
        return pw.Positioned(
          left: anno.rect.left,
          top: anno.rect.bottom - 2,
          child: pw.Container(
            width: anno.rect.width,
            height: 2,
            color: pw_pdf.PdfColor.fromInt(anno.color.toARGB32()),
          ),
        );

      case AnnotationType.strikethrough:
        return pw.Positioned(
          left: anno.rect.left,
          top: anno.rect.top + (anno.rect.height / 2),
          child: pw.Container(
            width: anno.rect.width,
            height: 2,
            color: pw_pdf.PdfColor.fromInt(anno.color.toARGB32()),
          ),
        );

      case AnnotationType.textBox:
      case AnnotationType.stickyNote:
        return pw.Positioned(
          left: anno.rect.left,
          top: anno.rect.top,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: anno.type == AnnotationType.stickyNote
                  ? pw_pdf.PdfColors.amber100
                  : pw_pdf.PdfColors.white,
              border: pw.Border.all(
                color: pw_pdf.PdfColor.fromInt(anno.color.toARGB32()),
                width: 1,
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              anno.text,
              style: pw.TextStyle(
                fontSize: 10,
                color: pw_pdf.PdfColor.fromInt(anno.color.toARGB32()),
              ),
            ),
          ),
        );

      case AnnotationType.rectangle:
        return pw.Positioned(
          left: anno.rect.left,
          top: anno.rect.top,
          child: pw.Container(
            width: anno.rect.width,
            height: anno.rect.height,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: pw_pdf.PdfColor.fromInt(anno.color.toARGB32()),
                width: anno.strokeWidth,
              ),
            ),
          ),
        );

      case AnnotationType.stamp:
        return pw.Positioned(
          left: anno.rect.left,
          top: anno.rect.top,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: pw_pdf.PdfColors.red, width: 2),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              anno.text.isEmpty ? 'APPROVED' : anno.text,
              style: pw.TextStyle(
                color: pw_pdf.PdfColors.red,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );

      default:
        // Freehand ink or custom shapes
        return pw.Positioned(
          left: anno.rect.left,
          top: anno.rect.top,
          child: pw.Container(
            width: anno.rect.width > 0 ? anno.rect.width : 20,
            height: anno.rect.height > 0 ? anno.rect.height : 20,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: pw_pdf.PdfColor.fromInt(anno.color.toARGB32()),
                width: anno.strokeWidth,
              ),
            ),
          ),
        );
    }
  }

  static Future<void> saveToDisk(Uint8List bytes, String targetPath) async {
    final file = File(targetPath);
    await file.writeAsBytes(bytes);
  }
}
