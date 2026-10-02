class RecentDocument {
  final String id;
  final String path;
  final String title;
  final int pageCount;
  final int lastPage;
  final int fileSize;
  final DateTime lastOpened;
  final bool isFavorite;

  const RecentDocument({
    required this.id,
    required this.path,
    required this.title,
    required this.pageCount,
    required this.lastPage,
    required this.fileSize,
    required this.lastOpened,
    this.isFavorite = false,
  });

  double get progress => pageCount > 0 ? (lastPage / pageCount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'title': title,
      'pageCount': pageCount,
      'lastPage': lastPage,
      'fileSize': fileSize,
      'lastOpened': lastOpened.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory RecentDocument.fromMap(Map<String, dynamic> map) {
    return RecentDocument(
      id: map['id'] as String,
      path: map['path'] as String,
      title: map['title'] as String,
      pageCount: map['pageCount'] as int,
      lastPage: map['lastPage'] as int,
      fileSize: map['fileSize'] as int,
      lastOpened: DateTime.parse(map['lastOpened'] as String),
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }

  RecentDocument copyWith({
    String? id,
    String? path,
    String? title,
    int? pageCount,
    int? lastPage,
    int? fileSize,
    DateTime? lastOpened,
    bool? isFavorite,
  }) {
    return RecentDocument(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      pageCount: pageCount ?? this.pageCount,
      lastPage: lastPage ?? this.lastPage,
      fileSize: fileSize ?? this.fileSize,
      lastOpened: lastOpened ?? this.lastOpened,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
