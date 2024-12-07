import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_article.freezed.dart';

@freezed
class NewsArticle with _$NewsArticle {
  const factory NewsArticle({
    required String id,
    required String ghostId,
    required String title,
    required String description,
    required String htmlContent,
    required DateTime publishedAt,
    required String imageUrl,
    required String slug,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<Author> authors,
    required List<Tag> tags,
    @Default(0) int upvotes,
    @Default(0) int downvotes,
    @Default(0) int userVote,  // 0: no vote, 1: upvote, -1: downvote
  }) = _NewsArticle;
}

@freezed
class Author with _$Author {
  const factory Author({
    required String id,
    required String name,
    required String slug,
    String? profileImage,
  }) = _Author;
}

@freezed
class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
    required String slug,
    String? description,
  }) = _Tag;
}