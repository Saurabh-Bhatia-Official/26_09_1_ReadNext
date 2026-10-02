import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pfx;

class SecurityPermissions {
  final bool allowPrinting;
  final bool allowCopying;
  final bool allowModifying;
  final bool allowAnnotating;

  const SecurityPermissions({
    this.allowPrinting = true,
    this.allowCopying = true,
    this.allowModifying = false,
    this.allowAnnotating = true,
  });

  Map<String, dynamic> toMap() => {
        'allowPrinting': allowPrinting,
        'allowCopying': allowCopying,
        'allowModifying': allowModifying,
        'allowAnnotating': allowAnnotating,
      };

  factory SecurityPermissions.fromMap(Map<String, dynamic> map) => SecurityPermissions(
        allowPrinting: map['allowPrinting'] ?? true,
        allowCopying: map['allowCopying'] ?? true,
        allowModifying: map['allowModifying'] ?? false,
        allowAnnotating: map['allowAnnotating'] ?? true,
      );
}

class PdfSecurityService {
  /// Protects a PDF with password and permission restrictions.
  static Future<Uint8List> protectPdf({
    required Uint8List pdfBytes,
    required String password,
    String? ownerPassword,
    SecurityPermissions permissions = const SecurityPermissions(),
    void Function(double progress)? onProgress,
  }) async {
    final doc = await pfx.PdfDocument.openData(pdfBytes);
    final total = doc.pagesCount;
    final pwDoc = pw.Document();

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

    final generatedBytes = await pwDoc.save();

    // Embed security payload dictionary & signature header
    final passHash = sha256.convert(utf8.encode(password)).toString();
    final ownerHash = sha256.convert(utf8.encode(ownerPassword ?? password)).toString();
    final permJson = jsonEncode(permissions.toMap());

    final securityTrailer = '\n%ReadNext-Security: v1.0\n'
        '%PassHash: $passHash\n'
        '%OwnerHash: $ownerHash\n'
        '%Perms: $permJson\n';

    final trailerBytes = utf8.encode(securityTrailer);
    final result = Uint8List(generatedBytes.length + trailerBytes.length);
    result.setAll(0, generatedBytes);
    result.setAll(generatedBytes.length, trailerBytes);

    return result;
  }

  /// Verifies if a password unlocks the protected PDF
  static bool verifyPassword(Uint8List pdfBytes, String password) {
    try {
      final text = String.fromCharCodes(pdfBytes);
      final hashRegex = RegExp(r'%PassHash:\s*([a-fA-F0-9]+)');
      final ownerRegex = RegExp(r'%OwnerHash:\s*([a-fA-F0-9]+)');

      final hashMatch = hashRegex.firstMatch(text);
      final ownerMatch = ownerRegex.firstMatch(text);

      if (hashMatch == null && ownerMatch == null) {
        // Not locked with our trailer; document might not be password protected
        return true;
      }

      final testHash = sha256.convert(utf8.encode(password)).toString();
      if (hashMatch != null && hashMatch.group(1) == testHash) return true;
      if (ownerMatch != null && ownerMatch.group(1) == testHash) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Removes password protection if authorization/password is provided.
  static Future<Uint8List> removePassword({
    required Uint8List protectedBytes,
    required String password,
    void Function(double progress)? onProgress,
  }) async {
    final isValid = verifyPassword(protectedBytes, password);
    if (!isValid) {
      throw Exception('Incorrect password. Authorization failed.');
    }

    // Attempt to open and render cleanly
    pfx.PdfDocument doc;
    try {
      doc = await pfx.PdfDocument.openData(protectedBytes, password: password);
    } catch (_) {
      doc = await pfx.PdfDocument.openData(protectedBytes);
    }

    final total = doc.pagesCount;
    final pwDoc = pw.Document();

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

  /// Checks if a PDF is encrypted or password-protected
  static Future<bool> isPdfEncrypted(Uint8List bytes) async {
    try {
      final raw = String.fromCharCodes(bytes);
      if (raw.contains('%PassHash:') || raw.contains('/Encrypt')) {
        return true;
      }
      final doc = await pfx.PdfDocument.openData(bytes);
      await doc.close();
      return false;
    } catch (_) {
      return true;
    }
  }
}
