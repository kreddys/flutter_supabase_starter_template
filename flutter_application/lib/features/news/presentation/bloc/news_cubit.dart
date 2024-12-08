import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_news_repository.dart';
import '../../domain/entities/news_article.dart';
import 'news_state.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

@injectable
class NewsCubit extends Cubit<NewsState> {
  final INewsRepository _newsRepository;
  final IVotingRepository _votingRepository;
  
  List<NewsArticle> _allArticles = [];
  List<NewsArticle> _searchResults = [];
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  String _selectedTag = 'All';
  String _searchQuery = '';
  Set<String> _allTags = {'All'};

NewsCubit(
  this._newsRepository,
  this._votingRepository,
) : super(const NewsState.initial()) {
  _loadAllTags(); // Initialize tags when cubit is created
}

  String get selectedTag => _selectedTag;
  Set<String> get allTags => _allTags;

  Future<void> _loadAllTags() async {
    final result = await _newsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 999999,
    );
    
    result.fold(
      (error) {
        AppLogger.error('Failed to load all tags: $error');
      },
      (articles) {
        _allTags = {'All', ...articles.expand((article) => article.tags).map((tag) => tag.name)};
      },
    );
  }

  Future<void> filterByTag(String tag) async {
    AppLogger.info('Filtering articles by tag: $tag');
    SentryMonitoring.addBreadcrumb(
      message: 'Filtering articles by tag',
      category: 'news',
      data: {'tag': tag},
    );

    _selectedTag = tag;
    _searchQuery = ''; // Clear search query when changing tags
    _currentPage = 1;
    _hasMoreData = true;
    _allArticles.clear();
    
    emit(const NewsState.loading());

    final result = await _newsRepository.getNewsArticles(
      page: _currentPage,
      itemsPerPage: _itemsPerPage,
      tagFilter: tag == 'All' ? null : tag,
    );
    
    result.fold(
      (error) {
        AppLogger.error('Failed to filter articles by tag: $error');
        SentryMonitoring.captureException(
          error,
          StackTrace.current,
          tagValue: 'tag_filter_failure',
        );
        emit(NewsState.error(error));
      },
      (articles) {
        _allArticles = articles;
        _hasMoreData = articles.length >= _itemsPerPage;
        emit(NewsState.loaded(
          articles: articles,
          isLoadingMore: false,
          hasMoreData: _hasMoreData,
        ));
      },
    );
  }

Future<void> loadNews() async {
  AppLogger.info('Loading initial news articles');
  SentryMonitoring.addBreadcrumb(
    message: 'Loading news articles',
    category: 'news',
    data: {'page': 1},
  );

  emit(const NewsState.loading());
  _currentPage = 1;
  _hasMoreData = true;
  _allArticles.clear();
  _searchQuery = ''; // Clear search query when loading all news

  final result = await _newsRepository.getNewsArticles(
    page: _currentPage,
    itemsPerPage: _itemsPerPage,
    tagFilter: _selectedTag == 'All' ? null : _selectedTag,
  );
  
  result.fold(
    (error) {
      AppLogger.error('Failed to load news articles: $error');
      SentryMonitoring.captureException(
        error,
        StackTrace.current,
        tagValue: 'news_load_failure',
      );
      emit(NewsState.error(error));
    },
    (articles) {
      AppLogger.info('Successfully loaded ${articles.length} articles');
      _allArticles = articles;
      // Update tags only if we don't have any yet
      if (_allTags.length <= 1) {
        _allTags = {'All', ...articles.expand((article) => article.tags).map((tag) => tag.name)};
      }
      _hasMoreData = articles.length >= _itemsPerPage;
      emit(NewsState.loaded(
        articles: articles,
        isLoadingMore: false,
        hasMoreData: _hasMoreData,
      ));
    },
  );
}

  Future<void> loadMoreArticles() async {
    if (!_hasMoreData || _isLoadingMore) {
      AppLogger.debug('Skipping loadMore - hasMoreData: $_hasMoreData, isLoadingMore: $_isLoadingMore');
      return;
    }

    AppLogger.info('Loading more articles - page: ${_currentPage + 1}');
    SentryMonitoring.addBreadcrumb(
      message: 'Loading more articles',
      category: 'news',
      data: {'page': _currentPage + 1},
    );

    _isLoadingMore = true;
    emit(NewsState.loaded(
      articles: _allArticles,
      isLoadingMore: true,
      hasMoreData: _hasMoreData,
    ));

    final result = await _newsRepository.getNewsArticles(
      page: _currentPage + 1,
      itemsPerPage: _itemsPerPage,
      tagFilter: _selectedTag == 'All' ? null : _selectedTag,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    result.fold(
      (error) {
        AppLogger.error('Failed to load more articles: $error');
        SentryMonitoring.captureException(
          error,
          StackTrace.current,
          tagValue: 'load_more_articles_failure',
        );
        _isLoadingMore = false;
        emit(NewsState.loaded(
          articles: _allArticles,
          isLoadingMore: false,
          hasMoreData: _hasMoreData,
        ));
      },
      (newArticles) {
        AppLogger.info('Successfully loaded ${newArticles.length} more articles');
        _currentPage++;
        _allArticles.addAll(newArticles);
        _hasMoreData = newArticles.length >= _itemsPerPage;
        _isLoadingMore = false;
        emit(NewsState.loaded(
          articles: _allArticles,
          isLoadingMore: false,
          hasMoreData: _hasMoreData,
        ));
      },
    );
  }

  void searchArticles(String query) {
    AppLogger.info('Performing local search with query: "$query"');
    
    if (query.isEmpty) {
      AppLogger.debug('Empty search query, showing all articles');
      emit(NewsState.loaded(
        articles: _allArticles,
        isLoadingMore: false,
        hasMoreData: _hasMoreData,
      ));
      return;
    }

    final filteredArticles = _allArticles.where((article) {
      final titleMatch = article.title.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = article.description.toLowerCase().contains(query.toLowerCase());
      return titleMatch || descriptionMatch;
    }).toList();

    AppLogger.info('Local search completed with ${filteredArticles.length} results');
    emit(NewsState.loaded(
      articles: filteredArticles,
      isLoadingMore: false,
      hasMoreData: false,
    ));
  }

  Future<void> searchAllArticles(String query) async {
    AppLogger.info('Performing API search with query: "$query"');
    SentryMonitoring.addBreadcrumb(
      message: 'Searching articles',
      category: 'news',
      data: {'query': query},
    );

    _searchQuery = query;

    if (query.isEmpty) {
      AppLogger.debug('Empty search query, loading all articles');
      _selectedTag = 'All'; // Reset tag selection when clearing search
      await loadNews();
      return;
    }

    emit(const NewsState.loading());
    
    final result = await _newsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 999999,
      searchQuery: query,
      tagFilter: _selectedTag == 'All' ? null : _selectedTag,
    );
    
    result.fold(
      (error) {
        AppLogger.error('Search failed: $error');
        SentryMonitoring.captureException(
          error,
          StackTrace.current,
          tagValue: 'search_articles_failure',
        );
        emit(NewsState.error(error));
      },
      (articles) {
        AppLogger.info('Search completed with ${articles.length} results');
        _searchResults = articles;
        emit(NewsState.loaded(
          articles: articles,
          isLoadingMore: false,
          hasMoreData: false,
        ));
      },
    );
  }

  Future<void> updateVoteAndRefresh({
    required String articleId,
    required VoteType? voteType,
  }) async {
    AppLogger.info('Updating vote for article: $articleId, vote type: $voteType');
    SentryMonitoring.addBreadcrumb(
      message: 'Updating article vote',
      category: 'news',
      data: {
        'articleId': articleId,
        'voteType': voteType?.toString(),
      },
    );

    final result = await _votingRepository.vote(
      entityId: articleId,
      entityType: EntityType.article,
      voteType: voteType,
    );

    result.fold(
      (error) {
        AppLogger.error('Failed to update vote: $error');
        SentryMonitoring.captureException(
          error,
          StackTrace.current,
          tagValue: 'update_vote_failure',
        );
        emit(NewsState.error(error));
      },
      (_) async {
        AppLogger.info('Vote updated successfully');
        loadNews();
      },
    );
  }

Future<void> updateVoteOnly({
  required String articleId,
  required VoteType? voteType,
}) async {
  try {
    // Use pattern matching with maybeWhen or when to handle the state
    final articles = state.maybeWhen(
      loaded: (articles, isLoadingMore, hasMoreData) => articles,
      orElse: () => null,
    );

    if (articles == null) {
      return;
    }

    // Update the vote in the repository
    final result = await _votingRepository.vote(
      entityId: articleId,
      entityType: EntityType.article,
      voteType: voteType,
    );

    await result.fold(
      (error) async {
        AppLogger.error('Error updating vote: $error');
        emit(NewsState.error(error));
      },
      (success) async {
        // Get updated vote counts
        final voteCounts = await _votingRepository.getVoteCounts(
          entityId: articleId,
          entityType: EntityType.article,
        );

        // Update only the specific article's vote counts
        final updatedArticles = articles.map((article) {
          if (article.id == articleId) {
            return article.copyWith(
              upvotes: voteCounts.fold(
                (l) => article.upvotes,
                (r) => r['upvotes'] ?? article.upvotes,
              ),
              downvotes: voteCounts.fold(
                (l) => article.downvotes,
                (r) => r['downvotes'] ?? article.downvotes,
              ),
              userVote: voteType == null ? 0 : (voteType == VoteType.upvote ? 1 : -1),
            );
          }
          return article;
        }).toList();

        // Get the current loading states using maybeWhen
        final (currentIsLoadingMore, currentHasMoreData) = state.maybeWhen(
          loaded: (_, isLoadingMore, hasMoreData) => (isLoadingMore, hasMoreData),
          orElse: () => (false, false),
        );

        // Emit new state with updated articles
        emit(NewsState.loaded(
          articles: updatedArticles,
          isLoadingMore: currentIsLoadingMore,
          hasMoreData: currentHasMoreData,
        ));
      },
    );
  } catch (error, stackTrace) {
    AppLogger.error('Error in updateVoteOnly', error: error, stackTrace: stackTrace);
    await SentryMonitoring.captureException(
      error,
      stackTrace,
      tagValue: 'vote_update_failure',
    );
    emit(NewsState.error(error.toString()));
  }
}

}