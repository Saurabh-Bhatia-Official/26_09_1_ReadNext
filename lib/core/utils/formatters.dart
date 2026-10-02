import 'dart:math';
import 'package:intl/intl.dart';

class Formatters {
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatFileSize(int bytes, [int decimals = 1]) => formatBytes(bytes, decimals);

  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
