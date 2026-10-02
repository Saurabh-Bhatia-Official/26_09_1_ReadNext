import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/data/models/bookmark_model.dart';
import 'package:read_next/data/models/pdf_document_meta.dart';
import 'package:read_next/data/models/recent_document.dart';

void main() {
  group('Data Models Tests', () {
    test('RecentDocument calculates progress and maps correctly', () {
      final doc = RecentDocument(
        id: 'p1',
        path: '/path/to/sample.pdf',
        title: 'Sample Document',
        pageCount: 10,
        lastPage: 5,
        fileSize: 10240,
        lastOpened: DateTime(2026, 9, 16),
        isFavorite: true,
      );

      expect(doc.progress, equals(0.5));
      expect(doc.isFavorite, isTrue);

      final map = doc.toMap();
      final restored = RecentDocument.fromMap(map);

      expect(restored.id, equals('p1'));
      expect(restored.title, equals('Sample Document'));
      expect(restored.progress, equals(0.5));
      expect(restored.isFavorite, isTrue);
    });

    test('PdfDocumentMeta initializes and copies with new values', () {
      final meta = PdfDocumentMeta(
        title: 'Invoice 2026',
        author: 'Finance Dept',
        pageCount: 4,
        fileSize: 2048,
        filePath: 'invoice.pdf',
      );

      expect(meta.title, equals('Invoice 2026'));
      expect(meta.pageCount, equals(4));

      final updated = meta.copyWith(title: 'Invoice 2026 Revised');
      expect(updated.title, equals('Invoice 2026 Revised'));
      expect(updated.author, equals('Finance Dept'));
    });

    test('BookmarkModel maps to and from map', () {
      final b = BookmarkModel(
        id: 'b1',
        documentPath: 'doc.pdf',
        pageNumber: 3,
        title: 'Chapter 1',
      );

      final map = b.toMap();
      final restored = BookmarkModel.fromMap(map);

      expect(restored.id, equals('b1'));
      expect(restored.pageNumber, equals(3));
      expect(restored.title, equals('Chapter 1'));
    });
  });
}
