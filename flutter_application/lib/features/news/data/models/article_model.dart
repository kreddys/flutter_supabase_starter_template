// /amaravati_chamber/lib/features/news/data/models/article_model.dart

class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String author;
  final DateTime publishedAt;
  final String imageUrl;
  final String htmlContent;
  final String slug;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.publishedAt,
    required this.imageUrl,
    required this.htmlContent,
    required this.slug,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String),
      imageUrl: json['image_url'] as String? ?? '',
      htmlContent: json['html_content'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}