import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/recent_document.dart';
import '../models/bookmark_model.dart';
import '../models/annotation_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath = '';
    if (!kIsWeb) {
      final appDocDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(appDocDir.path, 'read_next.db');
    } else {
      dbPath = 'read_next.db';
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recent_documents (
            id TEXT PRIMARY KEY,
            path TEXT UNIQUE,
            title TEXT,
            pageCount INTEGER,
            lastPage INTEGER,
            fileSize INTEGER,
            lastOpened TEXT,
            isFavorite INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE bookmarks (
            id TEXT PRIMARY KEY,
            documentPath TEXT,
            pageNumber INTEGER,
            title TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE annotations (
            id TEXT PRIMARY KEY,
            documentPath TEXT,
            pageNumber INTEGER,
            type TEXT,
            jsonData TEXT,
            updatedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT UNIQUE,
            searchedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE preferences (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  // --- Recent Documents ---
  Future<List<RecentDocument>> getRecentDocuments() async {
    final db = await database;
    final maps = await db.query(
      'recent_documents',
      orderBy: 'lastOpened DESC',
      limit: 20,
    );
    return maps.map((m) => RecentDocument.fromMap(m)).toList();
  }

  Future<void> upsertRecentDocument(RecentDocument doc) async {
    final db = await database;
    await db.insert(
      'recent_documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReadingProgress(String path, int lastPage) async {
    final db = await database;
    await db.update(
      'recent_documents',
      {
        'lastPage': lastPage,
        'lastOpened': DateTime.now().toIso8601String(),
      },
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  Future<void> toggleFavorite(String path, bool isFavorite) async {
    final db = await database;
    await db.update(
      'recent_documents',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  Future<void> deleteRecentDocument(String path) async {
    final db = await database;
    await db.delete('recent_documents', where: 'path = ?', whereArgs: [path]);
  }

  // --- Bookmarks ---
  Future<List<BookmarkModel>> getBookmarksForDocument(String docPath) async {
    final db = await database;
    final maps = await db.query(
      'bookmarks',
      where: 'documentPath = ?',
      whereArgs: [docPath],
      orderBy: 'pageNumber ASC',
    );
    return maps.map((m) => BookmarkModel.fromMap(m)).toList();
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
    final db = await database;
    await db.insert(
      'bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBookmark(String id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Annotations ---
  Future<List<AnnotationModel>> getAnnotationsForDocument(String docPath) async {
    final db = await database;
    final maps = await db.query(
      'annotations',
      where: 'documentPath = ?',
      whereArgs: [docPath],
    );
    final List<AnnotationModel> list = [];
    for (final m in maps) {
      try {
        final jsonMap = jsonDecode(m['jsonData'] as String) as Map<String, dynamic>;
        list.add(AnnotationModel.fromJson(jsonMap));
      } catch (e) {
        debugPrint('Failed to parse annotation: $e');
      }
    }
    return list;
  }

  Future<void> saveAnnotation(AnnotationModel annotation) async {
    final db = await database;
    await db.insert(
      'annotations',
      {
        'id': annotation.id,
        'documentPath': annotation.documentPath,
        'pageNumber': annotation.pageNumber,
        'type': annotation.type.name,
        'jsonData': jsonEncode(annotation.toJson()),
        'updatedAt': annotation.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAnnotation(String id) async {
    final db = await database;
    await db.delete('annotations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAnnotationsForDocument(String docPath) async {
    final db = await database;
    await db.delete('annotations', where: 'documentPath = ?', whereArgs: [docPath]);
  }

  // --- Search History ---
  Future<List<String>> getSearchHistory() async {
    final db = await database;
    final maps = await db.query(
      'search_history',
      orderBy: 'searchedAt DESC',
      limit: 15,
    );
    return maps.map((m) => m['query'] as String).toList();
  }

  Future<void> addSearchQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    final db = await database;
    await db.insert(
      'search_history',
      {
        'query': cleanQuery,
        'searchedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  // --- Preferences ---
  Future<String?> getPreference(String key) async {
    final db = await database;
    final maps = await db.query(
      'preferences',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert(
      'preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
