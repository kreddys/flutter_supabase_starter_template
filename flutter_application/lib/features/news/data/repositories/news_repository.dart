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
  Future<Either<String, List<NewsArticle>>> getNewsArticles({
    int page = 1,
    int itemsPerPage = 10,
    String? searchQuery,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'key': ApiConstants.ghostApiKey,
        'page': page.toString(),
        'limit': itemsPerPage.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      };

      // Create URL with query parameters
      final url = Uri.parse('${ApiConstants.ghostApiUrl}/ghost/api/content/posts/')
          .replace(queryParameters: queryParams);

      print('Fetching from URL: $url'); // Debug log

      final response = await _client.get(url);
      print('Response status code: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> posts = data['posts'];

        final articles = posts.map((post) => NewsArticle(
          id: post['id'],
          title: post['title'],
          description: post['excerpt'] ?? post['custom_excerpt'] ?? '',
          author: 'Amaravati Chamber',
          publishedAt: DateTime.parse(post['published_at']),
          imageUrl: post['feature_image'] ?? '',
          htmlContent: post['html'] ?? '',
        )).toList();

        print('Successfully parsed ${articles.length} articles'); // Debug log
        return Right(articles);
      } else {
        print('Error response: ${response.body}'); // Debug log
        return Left('Failed to fetch news articles. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error fetching news: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log
      return Left('Error fetching news articles: ${e.toString()}');
    }
  }
}