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

  NewsCubit(this._newsRepository) : super(const NewsState.initial());

  Future<void> loadNews() async {
    emit(const NewsState.loading());

    final result = await _newsRepository.getNewsArticles();
    
    result.fold(
      (error) => emit(NewsState.error(error)),
      (articles) {
        _allArticles = articles;
        emit(NewsState.loaded(articles));
      },
    );
  }

  void searchArticles(String query) {
    if (query.isEmpty) {
      emit(NewsState.loaded(_allArticles));
      return;
    }

    final filteredArticles = _allArticles.where((article) {
      final titleMatch = article.title.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = article.description.toLowerCase().contains(query.toLowerCase());
      return titleMatch || descriptionMatch;
    }).toList();

    emit(NewsState.loaded(filteredArticles));
  }
}