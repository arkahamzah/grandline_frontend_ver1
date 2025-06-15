class Series {
  final int id;
  final String title;
  final String? description;
  final String coverUrl;
  final String status;
  final int? comicsCount;
  final String createdAt;
  final String updatedAt;
  bool isFavorite; // Add this field

  Series({
    required this.id,
    required this.title,
    this.description,
    required this.coverUrl,
    required this.status,
    this.comicsCount,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false, // Add this
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      coverUrl: json['cover_url'],
      status: json['status'],
      comicsCount: json['comics_count'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isFavorite: json['is_favorite'] ?? false, // Add this
    );
  }
}