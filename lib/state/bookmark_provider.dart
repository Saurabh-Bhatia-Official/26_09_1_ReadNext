import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/app_database.dart';
import '../../data/models/bookmark_model.dart';
import '../../services/pdf/i_pdf_engine.dart';

class BookmarkState {
  final List<BookmarkModel> bookmarks;
  final List<OutlineItemModel> outline;

  const BookmarkState({
    this.bookmarks = const [],
    this.outline = const [],
  });

  BookmarkState copyWith({
    List<BookmarkModel>? bookmarks,
    List<OutlineItemModel>? outline,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      outline: outline ?? this.outline,
    );
  }
}

class BookmarkNotifier extends Notifier<BookmarkState> {
  @override
  BookmarkState build() {
    return const BookmarkState();
  }

  Future<void> loadForDocument(String? docPath, IPdfEngine engine) async {
    final outlineItems = await engine.getOutline();
    List<BookmarkModel> userBookmarks = [];
    if (docPath != null && docPath.isNotEmpty) {
      userBookmarks = await AppDatabase.instance.getBookmarksForDocument(docPath);
    }
    state = state.copyWith(
      outline: outlineItems,
      bookmarks: userBookmarks,
    );
  }

  Future<void> addBookmark(String docPath, int pageNumber, String title) async {
    final newBookmark = BookmarkModel(
      id: const Uuid().v4(),
      documentPath: docPath,
      pageNumber: pageNumber,
      title: title.isEmpty ? 'Page $pageNumber Bookmark' : title,
    );
    await AppDatabase.instance.addBookmark(newBookmark);
    state = state.copyWith(bookmarks: [...state.bookmarks, newBookmark]);
  }

  Future<void> deleteBookmark(String id) async {
    await AppDatabase.instance.deleteBookmark(id);
    state = state.copyWith(
      bookmarks: state.bookmarks.where((b) => b.id != id).toList(),
    );
  }
}

final bookmarkProvider = NotifierProvider<BookmarkNotifier, BookmarkState>(BookmarkNotifier.new);
