import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_news_repository.dart';
import '../../domain/entities/news_article.dart';
import 'news_state.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';

@injectable
class NewsCubit extends Cubit<NewsState> {
  final INewsRepository _newsRepository;
  final IVotingRepository _votingRepository; // Add this
  
  List<NewsArticle> _allArticles = [];
  List<NewsArticle> _searchResults = []; // New list for search results
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  NewsCubit(
        this._newsRepository,
        this._votingRepository, 
        ) : super(const NewsState.initial());

  Future<void> loadNews() async {
    emit(const NewsState.loading());
    _currentPage = 1;
    _hasMoreData = true;
    _allArticles.clear();

    final result = await _newsRepository.getNewsArticles(
      page: _currentPage,
      itemsPerPage: _itemsPerPage,
    );
    
    result.fold(
      (error) => emit(NewsState.error(error)),
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

  Future<void> loadMoreArticles() async {
    if (!_hasMoreData || _isLoadingMore) return;

    _isLoadingMore = true;
    emit(NewsState.loaded(
      articles: _allArticles,
      isLoadingMore: true,
      hasMoreData: _hasMoreData,
    ));

    final result = await _newsRepository.getNewsArticles(
      page: _currentPage + 1,
      itemsPerPage: _itemsPerPage,
    );

    result.fold(
      (error) {
        _isLoadingMore = false;
        emit(NewsState.error(error));
      },
      (newArticles) {
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

  // Local search functionality
  void searchArticles(String query) {
    if (query.isEmpty) {
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

    emit(NewsState.loaded(
      articles: filteredArticles,
      isLoadingMore: false,
      hasMoreData: false,
    ));
  }

  // API-based search functionality
  Future<void> searchAllArticles(String query) async {
    if (query.isEmpty) {
      emit(NewsState.loaded(
        articles: _searchResults = [], // Clear search results
        isLoadingMore: false,
        hasMoreData: _hasMoreData,
      ));
      return;
    }

    emit(const NewsState.loading());

    // Reset pagination values
    _currentPage = 1;
    _hasMoreData = true;
    
    final result = await _newsRepository.getNewsArticles(
      page: _currentPage,
      itemsPerPage: 999999, // Increased items per page for search
      searchQuery: query,
    );
    
    result.fold(
      (error) => emit(NewsState.error(error)),
      (articles) {
        _searchResults = articles; // Store search results separately
        emit(NewsState.loaded(
          articles: articles,
          isLoadingMore: false,
          hasMoreData: false, // We'll get all relevant results in one call for search
        ));
      },
    );
  }

  void restoreMainArticles() {
    emit(NewsState.loaded(
        articles: _allArticles,
        isLoadingMore: _isLoadingMore,
        hasMoreData: _hasMoreData,
      ));
  }

// In news_cubit.dart

Future<void> updateVote({
  required String articleId,
  required VoteType? voteType,
}) async {
  final result = await _votingRepository.vote(
    entityId: articleId,
    entityType: EntityType.article,
    voteType: voteType,
  );

  result.fold(
    (error) {
      // Handle error
    },
    (success) async {
      final voteCounts = await _votingRepository.getVoteCounts(
        entityId: articleId,
        entityType: EntityType.article,
      );

      voteCounts.fold(
        (error) {
          // Handle error
        },
        (counts) {
          final currentState = state;
          if (currentState is NewsState) {
            currentState.maybeWhen(
              loaded: (articles, isLoadingMore, hasMoreData) {
                // Update _allArticles
                _allArticles = _allArticles.map((article) {
                  if (article.id == articleId) {
                    return article.copyWith(
                      upvotes: counts['upvotes'] ?? 0,
                      downvotes: counts['downvotes'] ?? 0,
                      userVote: voteType == null 
                        ? 0 
                        : voteType == VoteType.upvote ? 1 : -1,
                    );
                  }
                  return article;
                }).toList();

                // Update _searchResults if they exist
                if (_searchResults.isNotEmpty) {
                  _searchResults = _searchResults.map((article) {
                    if (article.id == articleId) {
                      return article.copyWith(
                        upvotes: counts['upvotes'] ?? 0,
                        downvotes: counts['downvotes'] ?? 0,
                        userVote: voteType == null 
                          ? 0 
                          : voteType == VoteType.upvote ? 1 : -1,
                      );
                    }
                    return article;
                  }).toList();
                }

                // Update current view
                final updatedArticles = articles.map((article) {
                  if (article.id == articleId) {
                    return article.copyWith(
                      upvotes: counts['upvotes'] ?? 0,
                      downvotes: counts['downvotes'] ?? 0,
                      userVote: voteType == null 
                        ? 0 
                        : voteType == VoteType.upvote ? 1 : -1,
                    );
                  }
                  return article;
                }).toList();

                emit(NewsState.loaded(
                  articles: updatedArticles,
                  isLoadingMore: isLoadingMore,
                  hasMoreData: hasMoreData,
                ));
              },
              orElse: () {},
            );
          }
        },
      );
    },
  );
}

Future<void> updateVoteAndRefresh({
  required String articleId,
  required VoteType? voteType,
}) async {
  final result = await _votingRepository.vote(
    entityId: articleId,
    entityType: EntityType.article,
    voteType: voteType,
  );

  result.fold(
    (error) => emit(NewsState.error(error)),
    (_) async {
      final currentState = state;
      
      currentState.maybeWhen(
        loaded: (articles, isLoadingMore, hasMoreData) async {
          // Get both vote counts and user's vote status
          final voteCounts = await _votingRepository.getVoteCounts(
            entityId: articleId,
            entityType: EntityType.article,
          );
          
          final userVoteResult = await _votingRepository.getUserVote(
            entityId: articleId,
            entityType: EntityType.article,
          );

          voteCounts.fold(
            (error) => emit(NewsState.error(error)),
            (counts) {
              userVoteResult.fold(
                (error) => emit(NewsState.error(error)),
                (userVote) {
                  // Update articles with correct user vote status
                  final updatedArticles = articles.map((article) {
                    if (article.id == articleId) {
                      return article.copyWith(
                        upvotes: counts['upvotes'] ?? 0,
                        downvotes: counts['downvotes'] ?? 0,
                        userVote: userVote == null ? 0 :
                                 userVote == VoteType.upvote ? 1 : -1,
                      );
                    }
                    return article;
                  }).toList();

                  emit(NewsState.loaded(
                    articles: updatedArticles,
                    isLoadingMore: isLoadingMore,
                    hasMoreData: hasMoreData,
                  ));
                },
              );
            },
          );
        },
        orElse: () {},
      );
    },
  );
}

  // Helper method to check if currently loading
  bool get isLoading => state.maybeWhen(
    loading: () => true,
    orElse: () => false,
  );

  // Helper method to get current articles
  List<NewsArticle> get currentArticles => state.maybeWhen(
    loaded: (articles, _, __) => articles,
    orElse: () => [],
  );

  // Helper method to check if more data is available
  bool get hasMoreData => state.maybeWhen(
    loaded: (_, __, hasMore) => hasMore,
    orElse: () => false,
  );
}