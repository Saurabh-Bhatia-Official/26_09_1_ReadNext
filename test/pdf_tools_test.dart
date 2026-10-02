import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/services/pdf/pdf_compressor_service.dart';
import 'package:read_next/services/pdf/pdf_organizer_service.dart';
import 'package:read_next/services/pdf/pdf_security_service.dart';
import 'package:read_next/state/license_provider.dart';
import 'package:read_next/state/queue_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async {
      return '.';
    },
  );

  group('PdfOrganizerService tests', () {
    test('parsePageRangeString handles comma separated numbers and ranges into file groups', () {
      final groups = PdfOrganizerService.parsePageRangeString('1, 3, 5-7', 10);
      expect(groups, equals([[1], [3], [5, 6, 7]]));
    });

    test('parsePageRangeString clamps to total pages and ignores out-of-range', () {
      final groups = PdfOrganizerService.parsePageRangeString('0, 2-4, 8-12', 6);
      expect(groups, equals([[2, 3, 4], [6]]));
    });

    test('parsePageRangeString returns empty on invalid string', () {
      final groups = PdfOrganizerService.parsePageRangeString('abc, foo-bar', 10);
      expect(groups, isEmpty);
    });
  });

  group('PdfCompressorService CompressionResult tests', () {
    test('CompressionResult calculates reduction percentage and formats bytes correctly', () {
      final result = CompressionResult(
        compressedBytes: Uint8List(0),
        originalSize: 10000000, // ~9.54 MB
        compressedSize: 4000000, // ~3.81 MB
        reductionPercentage: 60.0,
        pageCount: 5,
      );

      expect(result.reductionPercentage, equals(60.0));
      expect(result.originalSizeFormatted.isNotEmpty, isTrue);
      expect(result.compressedSizeFormatted.isNotEmpty, isTrue);
    });
  });

  group('PdfSecurityService tests', () {
    test('verifyPassword validates hash correctly', () {
      final expectedHash = sha256.convert(utf8.encode('MySecurePassword123')).toString();
      final passTrailer = '\n%ReadNext-Security: v1.0\n%PassHash: $expectedHash\n';
      final testBytes = Uint8List.fromList(utf8.encode(passTrailer));

      expect(PdfSecurityService.verifyPassword(testBytes, 'MySecurePassword123'), isTrue);
      expect(PdfSecurityService.verifyPassword(testBytes, 'WrongPassword'), isFalse);
    });
  });

  group('LicenseState and LicenseNotifier tests', () {
    test('All models and tools are 100% free and accessible by default', () {
      const freeState = LicenseState(tier: LicenseTier.free);
      expect(freeState.isPremium, isTrue);
      expect(freeState.canAccess(PdfFeature.merge), isTrue);
      expect(freeState.canAccess(PdfFeature.split), isTrue);
      expect(freeState.canAccess(PdfFeature.ocr), isTrue);
      expect(freeState.canAccess(PdfFeature.batchProcessing), isTrue);
      expect(freeState.canAccess(PdfFeature.pdfToWord), isTrue);
      expect(freeState.canAccess(PdfFeature.pdfToExcel), isTrue);
      expect(freeState.canAccess(PdfFeature.watermark), isTrue);
      expect(freeState.canAccess(PdfFeature.securityPassword), isTrue);
    });

    test('LicenseNotifier demo and activation testing with ProviderContainer', () async {
      final container = ProviderContainer();
      final notifier = container.read(licenseProvider.notifier);

      expect(container.read(licenseProvider).isPremium, isTrue);
      expect(container.read(licenseProvider).canAccess(PdfFeature.ocr), isTrue);

      await notifier.setDemoPremium(true);
      expect(container.read(licenseProvider).isPremium, isTrue);

      await notifier.setFreeTier();
      expect(container.read(licenseProvider).isPremium, isTrue);

      final success = await notifier.activateLicense('READNEXT-VIP-2026-COMPLEX', plan: LicensePlan.annual);
      expect(success, isTrue);
      expect(container.read(licenseProvider).isPremium, isTrue);

      final fail = await notifier.activateLicense('');
      expect(fail, isFalse);
    });
  });

  group('QueueNotifier tests', () {
    test('Enqueue, update progress, complete, and remove tasks', () {
      final container = ProviderContainer();
      final queueNotifier = container.read(queueProvider.notifier);

      expect(container.read(queueProvider).items, isEmpty);

      final taskId = queueNotifier.enqueueTask(
        title: 'Merge PDFs',
        operationName: 'Merge',
      );

      final stateAfterEnqueue = container.read(queueProvider);
      expect(stateAfterEnqueue.items.length, equals(1));
      expect(stateAfterEnqueue.items.first.id, equals(taskId));
      expect(stateAfterEnqueue.items.first.status, equals(QueueItemStatus.queued));

      queueNotifier.startProcessing(taskId);
      expect(container.read(queueProvider).items.first.status, equals(QueueItemStatus.processing));

      queueNotifier.updateProgress(taskId, 0.5);
      final updatedTask = container.read(queueProvider).items.firstWhere((t) => t.id == taskId);
      expect(updatedTask.progress, equals(0.5));

      queueNotifier.completeTask(taskId, outputPath: 'C:/merged.pdf');
      final completedTask = container.read(queueProvider).items.firstWhere((t) => t.id == taskId);
      expect(completedTask.status, equals(QueueItemStatus.completed));
      expect(completedTask.outputPath, equals('C:/merged.pdf'));
      expect(completedTask.progress, equals(1.0));

      queueNotifier.removeItem(taskId);
      expect(container.read(queueProvider).items, isEmpty);
    });
  });
}
