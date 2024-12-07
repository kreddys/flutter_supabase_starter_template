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
    AppLogger.info(
      'Fetching news articles - Page: $page, ItemsPerPage: $itemsPerPage, SearchQuery: $searchQuery'
    );

    try {
      final offset = (page - 1) * itemsPerPage;
      
      // Updated query to include authors and tags through junction tables
      var query = _supabaseClient
          .from('articles')
          .select('''
            *,
            article_authors!inner (
              author:authors(*)
            ),
            article_tags!inner (
              tag:tags(*)
            )
          ''');

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

    if (tagFilter != null && tagFilter != 'All') {
      query = query.eq('article_tags.tag.name', tagFilter);
    }

      // Apply ordering and pagination
      final response = await query
          .order('published_at', ascending: false)
          .range(offset, offset + itemsPerPage - 1);

      AppLogger.debug('Fetched ${response.length} articles from database');

      final articles = await Future.wait((response as List<dynamic>).map((article) async {
        AppLogger.debug('Processing article ${article['id']}');
        
        // Extract authors from the nested response
        final authors = (article['article_authors'] as List<dynamic>)
            .map((authorData) => Author(
                  id: authorData['author']['id'],
                  name: authorData['author']['name'],
                  slug: authorData['author']['slug'],
                  profileImage: authorData['author']['profile_image'],
                ))
            .toList();

        // Extract tags from the nested response
        final tags = (article['article_tags'] as List<dynamic>)
            .map((tagData) => Tag(
                  id: tagData['tag']['id'],
                  name: tagData['tag']['name'],
                  slug: tagData['tag']['slug'],
                  description: tagData['tag']['description'],
                ))
            .toList();

        // Get vote counts and user vote
        final voteCounts = await _votingRepository.getVoteCounts(
          entityId: article['id'].toString(),
          entityType: EntityType.article,
        );

        final userVote = await _votingRepository.getUserVote(
          entityId: article['id'].toString(),
          entityType: EntityType.article,
        );

        return NewsArticle(
          id: article['id'].toString(),
          ghostId: article['ghost_id'],
          title: article['title'],
          description: article['description'] ?? '',
          htmlContent: article['html_content'],
          publishedAt: DateTime.parse(article['published_at']),
          imageUrl: article['image_url'] ?? '',
          slug: article['slug'],
          createdAt: DateTime.parse(article['created_at']),
          updatedAt: DateTime.parse(article['updated_at']),
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

      AppLogger.info('Successfully processed ${articles.length} articles');
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