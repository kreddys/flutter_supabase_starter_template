import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/i_news_repository.dart';

@LazySingleton(as: INewsRepository)
class NewsRepository implements INewsRepository {
  final SupabaseClient _supabaseClient;

  NewsRepository(this._supabaseClient);

  @override
  Future<Either<String, List<NewsArticle>>> getNewsArticles({
    int page = 1,
    int itemsPerPage = 10,
    String? searchQuery,
  }) async {
    try {
      final offset = (page - 1) * itemsPerPage;

      // Start with a base query
      final query = _supabaseClient
          .from('articles')
          .select();

      // Apply search filter if provided
      final filteredQuery = searchQuery != null && searchQuery.isNotEmpty
          ? query.textSearch('title', searchQuery)
          : query;

      // Execute the query with pagination and ordering
      final response = await filteredQuery
          .order('published_at', ascending: false)
          .range(offset, offset + itemsPerPage - 1);

      final List<NewsArticle> articles = (response as List<dynamic>)
          .map((post) => NewsArticle(
                id: post['id'],
                title: post['title'],
                description: post['description'] ?? '',
                author: post['author'] ?? 'Amaravati Chamber',
                publishedAt: DateTime.parse(post['published_at']),
                imageUrl: post['image_url'] ?? '',
                htmlContent: post['html_content'] ?? '',
              ))
          .toList();

      return Right(articles);
    } catch (e, stackTrace) {
      print('Error fetching news: $e');
      print('Stack trace: $stackTrace');
      return Left('Error fetching news articles: ${e.toString()}');
    }
  }
}