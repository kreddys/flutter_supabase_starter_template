class AuthorModel {
  final String id;
  final String ghostId;
  final String name;
  final String slug;
  final String? email;
  final String? profileImage;

  AuthorModel({
    required this.id,
    required this.ghostId,
    required this.name,
    required this.slug,
    this.email,
    this.profileImage,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] as String,
      ghostId: json['ghost_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String?,
    );
  }
}