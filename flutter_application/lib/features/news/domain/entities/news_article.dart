import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_article.freezed.dart';

@freezed
class NewsArticle with _$NewsArticle {
  const factory NewsArticle({
    required String id,
    required String title,
    required String description,
    required String author,
    required DateTime publishedAt,
    required String imageUrl,
    required String htmlContent,
    @Default(0) int upvotes,
    @Default(0) int downvotes,
    @Default(0) int userVote,  // 0: no vote, 1: upvote, -1: downvote
  }) = _NewsArticle;
}