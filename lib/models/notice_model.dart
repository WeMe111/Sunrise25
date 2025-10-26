class Notice {
  final String id;
  final String title;
  final String content;
  final String author;
  final String authorId;
  final String category;
  final int views;
  final bool isNew;
  final List<String> fileUrls;
  final List<String> fileNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.category,
    required this.views,
    required this.isNew,
    required this.fileUrls,
    required this.fileNames,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON에서 Notice 객체 생성
  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      authorId: json['author_id'] as String,
      category: json['category'] as String? ?? '일반',
      views: json['views'] as int? ?? 0,
      isNew: json['is_new'] as bool? ?? false,
      fileUrls: (json['file_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      fileNames: (json['file_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Notice 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'author_id': authorId,
      'category': category,
      'views': views,
      'is_new': isNew,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 데이터베이스 삽입용 (id, created_at, updated_at 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'author_id': authorId,
      'category': category,
      'views': views,
      'is_new': isNew,
    };
  }
}
