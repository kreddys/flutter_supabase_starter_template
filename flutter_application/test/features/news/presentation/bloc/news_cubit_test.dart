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

// Add these tests to your existing news_cubit_test.dart file

group('loadMoreArticles', () {
  test('should load more articles successfully', () async {
    // Arrange
    final initialArticles = List.generate(
      10,
      (i) => NewsArticle(
        id: 'test_$i',
        title: 'Test Article $i',
        description: 'Test Description $i',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'test$i.jpg',
        htmlContent: '<p>Test Content $i</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
    );

    final moreArticles = List.generate(
      5,
      (i) => NewsArticle(
        id: 'more_$i',
        title: 'More Article $i',
        description: 'More Description $i',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'more$i.jpg',
        htmlContent: '<p>More Content $i</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
    );

    when(mockNewsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 10,
    )).thenAnswer((_) async => Right(initialArticles));

    when(mockNewsRepository.getNewsArticles(
      page: 2,
      itemsPerPage: 10,
    )).thenAnswer((_) async => Right(moreArticles));

    // Act & Assert
    await newsCubit.loadNews();
    
    expectLater(
      newsCubit.stream,
      emitsInOrder([
        NewsState.loaded(
          articles: initialArticles,
          isLoadingMore: true,
          hasMoreData: true,
        ),
        NewsState.loaded(
          articles: [...initialArticles, ...moreArticles],
          isLoadingMore: false,
          hasMoreData: false,
        ),
      ]),
    );

    await newsCubit.loadMoreArticles();
  });

  test('should handle error when loading more articles', () async {
    // Arrange
    final initialArticles = List.generate(
      10,
      (i) => NewsArticle(
        id: 'test_$i',
        title: 'Test Article $i',
        description: 'Test Description $i',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'test$i.jpg',
        htmlContent: '<p>Test Content $i</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
    );

    when(mockNewsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 10,
    )).thenAnswer((_) async => Right(initialArticles));

    when(mockNewsRepository.getNewsArticles(
      page: 2,
      itemsPerPage: 10,
    )).thenAnswer((_) async => const Left('Error loading more articles'));

    // Act & Assert
    await newsCubit.loadNews();
    
    expectLater(
      newsCubit.stream,
      emitsInOrder([
        NewsState.loaded(
          articles: initialArticles,
          isLoadingMore: true,
          hasMoreData: true,
        ),
        NewsState.loaded(
          articles: initialArticles,
          isLoadingMore: false,
          hasMoreData: true,
        ),
      ]),
    );

    await newsCubit.loadMoreArticles();
  });
});

group('searchArticles', () {
  test('should filter articles locally', () async {
    // Arrange
    final articles = [
      NewsArticle(
        id: '1',
        title: 'Flutter Article',
        description: 'About Flutter',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'test.jpg',
        htmlContent: '<p>Content</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
      NewsArticle(
        id: '2',
        title: 'Dart Article',
        description: 'About Dart',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'test.jpg',
        htmlContent: '<p>Content</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
    ];

    when(mockNewsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 10,
    )).thenAnswer((_) async => Right(articles));

    // Act
    await newsCubit.loadNews();
    newsCubit.searchArticles('Flutter');

    // Assert
    expect(
      newsCubit.state,
      NewsState.loaded(
        articles: [articles[0]],
        isLoadingMore: false,
        hasMoreData: false,
      ),
    );
  });

  test('should return all articles when search query is empty', () async {
    // Arrange
    final articles = List.generate(
      2,
      (i) => NewsArticle(
        id: 'test_$i',
        title: 'Test Article $i',
        description: 'Test Description $i',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'test$i.jpg',
        htmlContent: '<p>Test Content $i</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
    );

    when(mockNewsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 10,
    )).thenAnswer((_) async => Right(articles));

    // Act
    await newsCubit.loadNews();
    newsCubit.searchArticles('');

    // Assert
    expect(
      newsCubit.state,
      NewsState.loaded(
        articles: articles,
        isLoadingMore: false,
        hasMoreData: false,
      ),
    );
  });
});

group('searchAllArticles', () {
  test('should search articles through API', () async {
    // Arrange
    final searchResults = List.generate(
      2,
      (i) => NewsArticle(
        id: 'search_$i',
        title: 'Search Result $i',
        description: 'Search Description $i',
        author: 'Test Author',
        publishedAt: DateTime.now(),
        imageUrl: 'search$i.jpg',
        htmlContent: '<p>Search Content $i</p>',
        upvotes: 0,
        downvotes: 0,
        userVote: 0,
      ),
    );

    when(mockNewsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 999999,
      searchQuery: 'test query',
    )).thenAnswer((_) async => Right(searchResults));

    // Assert
    expectLater(
      newsCubit.stream,
      emitsInOrder([
        const NewsState.loading(),
        NewsState.loaded(
          articles: searchResults,
          isLoadingMore: false,
          hasMoreData: false,
        ),
      ]),
    );

    // Act
    await newsCubit.searchAllArticles('test query');
  });

  test('should clear results when search query is empty', () async {
    // Assert
    expectLater(
      newsCubit.stream,
      emitsInOrder([
        const NewsState.loaded(
          articles: [],
          isLoadingMore: false,
          hasMoreData: true,
        ),
      ]),
    );

    // Act
    await newsCubit.searchAllArticles('');
  });

  test('should handle error during API search', () async {
    // Arrange
    when(mockNewsRepository.getNewsArticles(
      page: 1,
      itemsPerPage: 999999,
      searchQuery: 'test query',
    )).thenAnswer((_) async => const Left('Search failed'));

    // Assert
    expectLater(
      newsCubit.stream,
      emitsInOrder([
        const NewsState.loading(),
        const NewsState.error('Search failed'),
      ]),
    );

    // Act
    await newsCubit.searchAllArticles('test query');
  });
});


}