import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/news_article.dart';

part 'news_state.freezed.dart'; 

@freezed
class NewsState with _$NewsState {
  const factory NewsState.initial() = _Initial;
  const factory NewsState.loading() = _Loading;
  const factory NewsState.loaded(List<NewsArticle> articles) = _Loaded;
  const factory NewsState.error(String message) = _Error;
}