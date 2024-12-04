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
  }) async {
    AppLogger.info(
      'Fetching news articles - Page: $page, ItemsPerPage: $itemsPerPage, SearchQuery: $searchQuery'
    );

    try {
      final offset = (page - 1) * itemsPerPage;
      final query = _supabaseClient.from('articles').select();

      final filteredQuery = searchQuery != null && searchQuery.isNotEmpty
          ? query.ilike('title', '%$searchQuery%')
          : query;

      final response = await filteredQuery
          .order('published_at', ascending: false)
          .range(offset, offset + itemsPerPage - 1);

      AppLogger.debug('Fetched ${response.length} articles from database');

      final articles = await Future.wait((response as List<dynamic>).map((post) async {
        AppLogger.debug('Processing article ${post['id']}');
        
        final voteCounts = await _votingRepository.getVoteCounts(
          entityId: post['id'].toString(),
          entityType: EntityType.article,
        );

        final userVote = await _votingRepository.getUserVote(
          entityId: post['id'].toString(),
          entityType: EntityType.article,
        );

        return NewsArticle(
          id: post['id'].toString(),
          title: post['title'],
          description: post['description'] ?? '',
          author: post['author'] ?? 'Amaravati Chamber',
          publishedAt: DateTime.parse(post['published_at']),
          imageUrl: post['image_url'] ?? '',
          htmlContent: post['html_content'] ?? '',
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