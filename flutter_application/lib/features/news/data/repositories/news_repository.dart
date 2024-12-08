import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/i_news_repository.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

@LazySingleton(as: INewsRepository)
class NewsRepository implements INewsRepository {
  final SupabaseClient _supabaseClient;
  final IVotingRepository _votingRepository;

  NewsRepository(this._supabaseClient, this._votingRepository);

@override
Future<Either<String, List<NewsArticle>>> getNewsArticles({
  int page = 1,
  int itemsPerPage = 10,
  String? searchQuery,
  String? tagFilter,
}) async {
  try {
    final offset = (page - 1) * itemsPerPage;
    
    AppLogger.debug('Fetching articles with parameters:');
    AppLogger.debug('Page: $page');
    AppLogger.debug('Items per page: $itemsPerPage');
    AppLogger.debug('Search query: $searchQuery');
    AppLogger.debug('Tag filter: $tagFilter');
    AppLogger.debug('Offset: $offset');

    // Build the base query
    var query = _supabaseClient
        .from('articles')
        .select('''
          *,
          article_authors!inner(
            author:authors(*)
          ),
          article_tags!inner(
            tag:tags!inner(*)
          )
        ''');

    // Apply search filter if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.like('title', '%$searchQuery%'); // Changed from ilike to like
      AppLogger.debug('Applied search filter: $searchQuery');
    }

    // Apply tag filter if provided
    if (tagFilter != null && tagFilter != 'All') {
      query = query.eq('article_tags.tag.name', tagFilter); // Using eq instead of filter
      AppLogger.debug('Applied tag filter: $tagFilter');
    }

    // Execute the query with pagination and ordering
    final response = await query
        .order('published_at', ascending: false)
        .range(offset, offset + itemsPerPage - 1);
    
    AppLogger.debug('Number of articles retrieved: ${response?.length ?? 0}');

    if (response == null) {
      AppLogger.error('Null response from Supabase');
      return const Left('Error: No data received from server');
    }

    //AppLogger.debug('Raw response from Supabase: $response');

    final articles = await Future.wait((response as List<dynamic>).map((article) async {
      // Add null checks for article_authors and article_tags
      final articleAuthors = (article['article_authors'] as List<dynamic>?) ?? [];
      final articleTags = (article['article_tags'] as List<dynamic>?) ?? [];

      final authors = articleAuthors.map((authorData) {
        final authorInfo = authorData['author'];
        return Author(
          id: authorInfo?['id']?.toString() ?? '',
          name: authorInfo?['name'] ?? '',
          slug: authorInfo?['slug'] ?? '',
          profileImage: authorInfo?['profile_image'],
        );
      }).toList();

      final tags = articleTags.map((tagData) {
        final tagInfo = tagData['tag'];
        return Tag(
          id: tagInfo?['id']?.toString() ?? '',
          name: tagInfo?['name'] ?? '',
          slug: tagInfo?['slug'] ?? '',
          description: tagInfo?['description'],
        );
      }).toList();

      final voteCounts = await _votingRepository.getVoteCounts(
        entityId: article['id'].toString(),
        entityType: EntityType.article,
      );

      final userVote = await _votingRepository.getUserVote(
        entityId: article['id'].toString(),
        entityType: EntityType.article,
      );

      return NewsArticle(
        id: article['id']?.toString() ?? '',
        ghostId: article['ghost_id'] ?? '',
        title: article['title'] ?? '',
        description: article['description'] ?? '',
        htmlContent: article['html_content'] ?? '',
        publishedAt: DateTime.parse(article['published_at'] ?? DateTime.now().toIso8601String()),
        imageUrl: article['image_url'] ?? '',
        slug: article['slug'] ?? '',
        createdAt: DateTime.parse(article['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(article['updated_at'] ?? DateTime.now().toIso8601String()),
        authors: authors,
        tags: tags,
        upvotes: voteCounts.fold(
          (l) => 0,
          (r) => r['upvotes'] ?? 0,
        ),
        downvotes: voteCounts.fold(
          (l) => 0,
          (r) => r['downvotes'] ?? 0,
        ),
        userVote: userVote.fold(
          (l) => 0,
          (r) => r == null ? 0 : (r == VoteType.upvote ? 1 : -1),
        ),
      );
    }).toList());

    return Right(articles);
  } catch (e, stackTrace) {
    AppLogger.error(
      'Error fetching news articles: ${e.toString()}',
      error: e,
      stackTrace: stackTrace,
    );
    await SentryMonitoring.captureException(
      e,
      stackTrace,
      tagValue: 'news_fetch_failure',
    );
    return Left('Error fetching news articles: ${e.toString()}');
  }
}
}