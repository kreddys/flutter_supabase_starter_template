import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:amaravati_chamber/features/news/domain/repositories/i_news_repository.dart';
import 'package:amaravati_chamber/features/news/presentation/bloc/news_cubit.dart';
import 'package:amaravati_chamber/features/news/presentation/bloc/news_state.dart';
import 'package:amaravati_chamber/core/voting/domain/repositories/i_voting_repository.dart';
import 'package:amaravati_chamber/features/news/domain/entities/news_article.dart';

import 'news_cubit_test.mocks.dart';

@GenerateMocks([INewsRepository, IVotingRepository])
void main() {
  late NewsCubit newsCubit;
  late MockINewsRepository mockNewsRepository;
  late MockIVotingRepository mockVotingRepository;

  setUp(() {
    mockNewsRepository = MockINewsRepository();
    mockVotingRepository = MockIVotingRepository();
    newsCubit = NewsCubit(mockNewsRepository, mockVotingRepository);
  });

  tearDown(() {
    newsCubit.close();
  });

  group('NewsCubit Tests', () {
    test('initial state should be NewsState.initial', () {
      expect(newsCubit.state, const NewsState.initial());
    });

    test('should load news articles successfully', () async {
      // Arrange
      final testArticles = [
        NewsArticle(
          id: '1',
          title: 'Test Article',
          description: 'Test Description',
          author: 'Test Author',
          publishedAt: DateTime.now(),
          imageUrl: 'test.jpg',
          htmlContent: '<p>Test</p>',
        ),
      ];

      when(mockNewsRepository.getNewsArticles(
        page: 1,
        itemsPerPage: 10,
      )).thenAnswer((_) async => Right(testArticles));

      // Act
      await newsCubit.loadNews();

      // Assert
      verify(mockNewsRepository.getNewsArticles(
        page: 1,
        itemsPerPage: 10,
      )).called(1);

      expect(
        newsCubit.state,
        NewsState.loaded(
          articles: testArticles,
          isLoadingMore: false,
          hasMoreData: true,
        ),
      );
    });

    test('should emit error state when loading fails', () async {
      // Arrange
      const errorMessage = 'Failed to load news';
      when(mockNewsRepository.getNewsArticles(
        page: 1,
        itemsPerPage: 10,
      )).thenAnswer((_) async => const Left(errorMessage));

      // Act
      await newsCubit.loadNews();

      // Assert
      verify(mockNewsRepository.getNewsArticles(
        page: 1,
        itemsPerPage: 10,
      )).called(1);

      expect(newsCubit.state, const NewsState.error(errorMessage));
    });

    test('should load more news articles successfully', () async {
      // Arrange
      final initialArticles = [
        NewsArticle(
          id: '1',
          title: 'Initial Article',
          description: 'Initial Description',
          author: 'Test Author',
          publishedAt: DateTime.now(),
          imageUrl: 'test.jpg',
          htmlContent: '<p>Test</p>',
        ),
      ];

      final moreArticles = [
        NewsArticle(
          id: '2',
          title: 'More Article',
          description: 'More Description',
          author: 'Test Author',
          publishedAt: DateTime.now(),
          imageUrl: 'test.jpg',
          htmlContent: '<p>Test</p>',
        ),
      ];

      // Set up initial state
      when(mockNewsRepository.getNewsArticles(
        page: 1,
        itemsPerPage: 10,
      )).thenAnswer((_) async => Right(initialArticles));

      await newsCubit.loadNews();

      // Set up load more
      when(mockNewsRepository.getNewsArticles(
        page: 2,
        itemsPerPage: 10,
      )).thenAnswer((_) async => Right(moreArticles));

      // Act
      await newsCubit.loadMoreArticles();

      // Assert
      verify(mockNewsRepository.getNewsArticles(
        page: 2,
        itemsPerPage: 10,
      )).called(1);

      expect(
        newsCubit.state,
        NewsState.loaded(
          articles: [...initialArticles, ...moreArticles],
          isLoadingMore: false,
          hasMoreData: true,
        ),
      );
    });
  });
}