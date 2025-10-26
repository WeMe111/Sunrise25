class Gallery {
  final String id;
  final String title;
  final String? description;
  final String author;
  final String authorId;
  final int views;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  Gallery({
    required this.id,
    required this.title,
    this.description,
    required this.author,
    required this.authorId,
    required this.views,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON에서 Gallery 객체 생성
  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      author: json['author'] as String,
      authorId: json['author_id'] as String,
      views: json['views'] as int? ?? 0,
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Gallery 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'author_id': authorId,
      'views': views,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 데이터베이스 삽입용
  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'author_id': authorId,
      'views': views,
      'image_urls': imageUrls,
    };
  }
}
