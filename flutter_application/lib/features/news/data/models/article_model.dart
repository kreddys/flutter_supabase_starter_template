class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String htmlContent;
  final DateTime publishedAt;
  final String imageUrl;
  final String slug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ghostId; // New field to match Supabase schema

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.htmlContent,
    required this.publishedAt,
    required this.imageUrl,
    required this.slug,
    required this.createdAt,
    required this.updatedAt,
    required this.ghostId,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      htmlContent: json['html_content'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      imageUrl: json['image_url'] as String? ?? '',
      slug: json['slug'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      ghostId: json['ghost_id'] as String,
    );
  }
}