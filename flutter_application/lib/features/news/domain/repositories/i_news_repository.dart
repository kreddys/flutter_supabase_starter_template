import 'package:dartz/dartz.dart';
import '../entities/news_article.dart';

abstract class INewsRepository {
  Future<Either<String, List<NewsArticle>>> getNewsArticles();
}