import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/data/models/annotation_model.dart';
import 'package:read_next/state/annotation_provider.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async => '.',
  );

  group('AnnotationModel Tests', () {
    test('JSON serialization and deserialization preserves all fields', () {
      final anno = AnnotationModel(
        id: 'test-1',
        documentPath: 'doc.pdf',
        pageNumber: 2,
        type: AnnotationType.highlight,
        color: const Color(0xFFFFEB3B),
        opacity: 0.5,
        strokeWidth: 4.0,
        rect: const Rect.fromLTWH(10, 20, 100, 30),
        text: 'Important passage',
        author: 'Tester',
      );

      final json = anno.toJson();
      final restored = AnnotationModel.fromJson(json);

      expect(restored.id, equals('test-1'));
      expect(restored.documentPath, equals('doc.pdf'));
      expect(restored.pageNumber, equals(2));
      expect(restored.type, equals(AnnotationType.highlight));
      expect(restored.rect.left, equals(10.0));
      expect(restored.rect.width, equals(100.0));
      expect(restored.text, equals('Important passage'));
      expect(restored.author, equals('Tester'));
    });
  });

  group('AnnotationNotifier Undo / Redo Tests', () {
    test('Undo and Redo maintain correct history stack', () {
      final container = ProviderContainer();
      final notifier = container.read(annotationProvider.notifier);

      expect(container.read(annotationProvider).canUndo, isFalse);
      expect(container.read(annotationProvider).canRedo, isFalse);

      final anno1 = AnnotationModel(
        id: 'anno-1',
        documentPath: 'doc.pdf',
        pageNumber: 1,
        type: AnnotationType.rectangle,
        color: Colors.red,
        rect: const Rect.fromLTWH(0, 0, 50, 50),
      );

      notifier.addAnnotation(anno1);
      expect(container.read(annotationProvider).annotations.length, equals(1));
      expect(container.read(annotationProvider).canUndo, isTrue);
      expect(container.read(annotationProvider).canRedo, isFalse);

      final anno2 = AnnotationModel(
        id: 'anno-2',
        documentPath: 'doc.pdf',
        pageNumber: 1,
        type: AnnotationType.circle,
        color: Colors.blue,
        rect: const Rect.fromLTWH(60, 60, 40, 40),
      );

      notifier.addAnnotation(anno2);
      expect(container.read(annotationProvider).annotations.length, equals(2));

      // Undo
      notifier.undo();
      expect(container.read(annotationProvider).annotations.length, equals(1));
      expect(container.read(annotationProvider).canRedo, isTrue);

      // Redo
      notifier.redo();
      expect(container.read(annotationProvider).annotations.length, equals(2));
    });
  });
}
