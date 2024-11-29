import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_news_repository.dart';
import 'news_state.dart';

@injectable
class NewsCubit extends Cubit<NewsState> {
  final INewsRepository _newsRepository;

  NewsCubit(this._newsRepository) : super(const NewsState.initial());

  Future<void> loadNews() async {
    emit(const NewsState.loading());

    final result = await _newsRepository.getNewsArticles();
    
    result.fold(
      (error) => emit(NewsState.error(error)),
      (articles) => emit(NewsState.loaded(articles)),
    );
  }
}