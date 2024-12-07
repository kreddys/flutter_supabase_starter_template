class TagModel {
  final String id;
  final String ghostId;
  final String name;
  final String slug;
  final String? description;

  TagModel({
    required this.id,
    required this.ghostId,
    required this.name,
    required this.slug,
    this.description,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      ghostId: json['ghost_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
    );
  }
}