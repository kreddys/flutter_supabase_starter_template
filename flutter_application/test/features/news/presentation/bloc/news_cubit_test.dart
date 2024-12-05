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

  group('NewsCubit', () {
    final testArticles = [
      NewsArticle(
        id: 'test_1',
        title: 'Test Article 1',
        description: 'Test Description 1',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'test1.jpg',
        htmlContent: '<p>Test Content 1</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
      NewsArticle(
        id: 'test_2',
        title: 'Test Article 2',
        description: 'Test Description 2',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'test2.jpg',
        htmlContent: '<p>Test Content 2</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
    ];

    test('initial state should be NewsState.initial()', () {
      expect(newsCubit.state, equals(const NewsState.initial()));
    });

    test('loadNews should emit loaded state on success', () async {
      // Arrange
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
          hasMoreData: false,
        ),
      );
    });

    test('loadNews should emit error state on failure', () async {
      // Arrange
      const errorMessage = 'Failed to load articles';
      when(mockNewsRepository.getNewsArticles(
        page: 1,
        itemsPerPage: 10,
      )).thenAnswer((_) async => const Left(errorMessage));

      // Act
      await newsCubit.loadNews();

      // Assert
      expect(
        newsCubit.state,
        const NewsState.error(errorMessage),
      );
    });

    test('loadMoreArticles should handle error while keeping existing articles',
        () async {
      // Arrange
      when(mockNewsRepository.getNewsArticles(
        page: 1,
        itemsPerPage: 10,
      )).thenAnswer((_) async => Right(testArticles));

      const errorMessage = 'Failed to load more articles';
      when(mockNewsRepository.getNewsArticles(
        page: 2,
        itemsPerPage: 10,
      )).thenAnswer((_) async => const Left(errorMessage));

      // Load initial articles
      await newsCubit.loadNews();

      // Act
      await newsCubit.loadMoreArticles();

      // Assert
      expect(
        newsCubit.state,
        NewsState.loaded(
          articles: testArticles,
          isLoadingMore: false,
          hasMoreData: false,
        ),
      );
    });
  });
}