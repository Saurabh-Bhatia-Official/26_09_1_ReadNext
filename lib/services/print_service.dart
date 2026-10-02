import 'dart:typed_data';
import 'package:printing/printing.dart';

class PrintService {
  static Future<bool> printPdf(Uint8List bytes, {String name = 'Document'}) async {
    try {
      return await Printing.layoutPdf(
        name: name,
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      return false;
    }
  }
}
