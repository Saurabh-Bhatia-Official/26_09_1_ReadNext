class BookmarkModel {
  final String id;
  final String documentPath;
  final int pageNumber;
  final String title;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.documentPath,
    required this.pageNumber,
    required this.title,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentPath': documentPath,
      'pageNumber': pageNumber,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as String,
      documentPath: map['documentPath'] as String,
      pageNumber: map['pageNumber'] as int,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class OutlineItemModel {
  final String title;
  final int pageNumber;
  final List<OutlineItemModel> children;

  const OutlineItemModel({
    required this.title,
    required this.pageNumber,
    this.children = const [],
  });
}
