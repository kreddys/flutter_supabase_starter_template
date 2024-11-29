// lib/features/news/presentation/bloc/news_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_news_repository.dart';
import '../../domain/entities/news_article.dart';
import 'news_state.dart';

@injectable
class NewsCubit extends Cubit<NewsState> {
  final INewsRepository _newsRepository;
  List<NewsArticle> _allArticles = [];
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  NewsCubit(this._newsRepository) : super(const NewsState.initial());

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
}