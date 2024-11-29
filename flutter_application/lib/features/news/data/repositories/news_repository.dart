import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/i_news_repository.dart';

@Injectable(as: INewsRepository)
class NewsRepository implements INewsRepository {
  @override
  Future<Either<String, List<NewsArticle>>> getNewsArticles() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final dummyArticles = [
        NewsArticle(
          id: '1',
          title: 'Flutter 3.0 Released',
          description: 'New features and improvements in Flutter 3.0',
          author: 'Flutter Team',
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NewsArticle(
          id: '2',
          title: 'Dart 3 Announcement',
          description: 'Exploring the new features in Dart 3',
          author: 'Dart Team',
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      return Right(dummyArticles);
    } catch (e) {
      return Left(e.toString());
    }
  }
}