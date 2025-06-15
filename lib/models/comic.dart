import 'series.dart';

class Comic {
  final int id;
  final int seriesId;
  final String chapterNumber;
  final String title;
  final String? description;
  final String coverUrl;
  final List<String> pagesUrls;
  final int pageCount;
  final Series? series;

  Comic({
    required this.id,
    required this.seriesId,
    required this.chapterNumber,
    required this.title,
    this.description,
    required this.coverUrl,
    required this.pagesUrls,
    required this.pageCount,
    this.series,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['id'],
      seriesId: json['series_id'],
      chapterNumber: json['chapter_number'],
      title: json['title'],
      description: json['description'],
      coverUrl: json['cover_url'],
      pagesUrls: List<String>.from(json['pages_urls'] ?? []),
      pageCount: json['page_count'],
      series: json['series'] != null ? Series.fromJson(json['series']) : null,
    );
  }
}