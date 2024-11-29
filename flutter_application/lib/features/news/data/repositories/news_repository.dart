import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/i_news_repository.dart';
import '../../../../core/constants/api_constants.dart';

@LazySingleton(as: INewsRepository) 
class NewsRepository implements INewsRepository {
  final http.Client _client;

  NewsRepository(this._client);

  @override
  Future<Either<String, List<NewsArticle>>> getNewsArticles() async {
    try {
      final url = Uri.parse(
          '${ApiConstants.ghostApiUrl}/ghost/api/v3/content/posts/?key=${ApiConstants.ghostApiKey}&fields=title,excerpt,published_at,slug,authors'
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> posts = data['posts'];

        final articles = posts.map((post) => NewsArticle(
          id: post['slug'],
          title: post['title'],
          description: post['excerpt'] ?? '',
          author: post['authors']?[0]?['name'] ?? 'Unknown',
          publishedAt: DateTime.parse(post['published_at']),
        )).toList();

        return Right(articles);
      } else {
        return const Left('Failed to fetch news articles');
      }
    } catch (e) {
      return Left(e.toString());
    }
  }
}