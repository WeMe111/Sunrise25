class PressRelease {
  final String id;
  final String title;
  final String content;
  final String author;
  final String authorId;
  final List<String> fileUrls;
  final List<String> fileNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  PressRelease({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.fileUrls,
    required this.fileNames,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON에서 PressRelease 객체 생성
  factory PressRelease.fromJson(Map<String, dynamic> json) {
    return PressRelease(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      authorId: json['author_id'] as String,
      fileUrls: (json['file_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      fileNames: (json['file_names'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // PressRelease 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'author_id': authorId,
      'file_urls': fileUrls,
      'file_names': fileNames,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 데이터베이스 삽입용
  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'author_id': authorId,
      'file_urls': fileUrls,
      'file_names': fileNames,
    };
  }
}
