import 'dart:typed_data';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pfx;

class EditablePdfMetadata {
  final String title;
  final String author;
  final String subject;
  final String keywords;
  final String creator;
  final String producer;

  const EditablePdfMetadata({
    this.title = '',
    this.author = '',
    this.subject = '',
    this.keywords = '',
    this.creator = 'ReadNext by Complex Innovators',
    this.producer = 'ReadNext PDF Engine',
  });

  EditablePdfMetadata copyWith({
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? creator,
    String? producer,
  }) {
    return EditablePdfMetadata(
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      keywords: keywords ?? this.keywords,
      creator: creator ?? this.creator,
      producer: producer ?? this.producer,
    );
  }
}

class PdfMetadataService {
  /// Reads metadata strings from PDF bytes stream dictionaries
  static Future<EditablePdfMetadata> readMetadata(Uint8List bytes) async {
    try {
      final raw = String.fromCharCodes(bytes);

      String findValue(String key) {
        final regex = RegExp('/$key\\s*\\((.*?)\\)');
        final match = regex.firstMatch(raw);
        if (match != null) {
          return match.group(1)?.replaceAll(r'\)', ')').replaceAll(r'\(', '(') ?? '';
        }
        return '';
      }

      return EditablePdfMetadata(
        title: findValue('Title'),
        author: findValue('Author'),
        subject: findValue('Subject'),
        keywords: findValue('Keywords'),
        creator: findValue('Creator').isNotEmpty ? findValue('Creator') : 'ReadNext by Complex Innovators',
        producer: findValue('Producer').isNotEmpty ? findValue('Producer') : 'ReadNext PDF Engine',
      );
    } catch (_) {
      return const EditablePdfMetadata();
    }
  }

  /// Rewrites the PDF document with updated metadata
  static Future<Uint8List> updateMetadata({
    required Uint8List pdfBytes,
    required EditablePdfMetadata metadata,
    void Function(double progress)? onProgress,
  }) async {
    final doc = await pfx.PdfDocument.openData(pdfBytes);
    final total = doc.pagesCount;
    final pwDoc = pw.Document(
      title: metadata.title,
      author: metadata.author,
      subject: metadata.subject,
      keywords: metadata.keywords,
      creator: metadata.creator,
      producer: metadata.producer,
    );

    for (int p = 1; p <= total; p++) {
      final page = await doc.getPage(p);
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

      if (onProgress != null) onProgress(p / total);
    }

    await doc.close();
    return await pwDoc.save();
  }

  /// Batch update metadata for multiple PDFs
  static Future<List<Uint8List>> batchUpdateMetadata({
    required List<Uint8List> docList,
    required EditablePdfMetadata metadataTemplate,
    void Function(double progress)? onProgress,
  }) async {
    final List<Uint8List> result = [];
    int idx = 0;
    for (final docBytes in docList) {
      final updated = await updateMetadata(
        pdfBytes: docBytes,
        metadata: metadataTemplate,
      );
      result.add(updated);
      idx++;
      if (onProgress != null) onProgress(idx / docList.length);
    }
    return result;
  }
}
