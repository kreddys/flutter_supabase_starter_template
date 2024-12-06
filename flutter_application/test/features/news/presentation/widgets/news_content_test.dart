import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:amaravati_chamber/features/news/presentation/bloc/news_cubit.dart';
import 'package:amaravati_chamber/features/news/presentation/bloc/news_state.dart';
import 'package:amaravati_chamber/features/news/presentation/widgets/news_content.dart';
import 'package:amaravati_chamber/features/news/domain/entities/news_article.dart';
import 'package:amaravati_chamber/core/voting/domain/repositories/i_voting_repository.dart';

@GenerateNiceMocks([MockSpec<NewsCubit>()])
import 'news_content_test.mocks.dart';

void main() {
  late MockNewsCubit mockNewsCubit;

  setUp(() {
    mockNewsCubit = MockNewsCubit();
    // Setup default stream behavior
    when(mockNewsCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<NewsCubit>.value(
        value: mockNewsCubit,
        child: const NewsContent(),
      ),
    );
  }

  group('NewsContent Widget', () {
    testWidgets('initializes and loads news on start', (WidgetTester tester) async {
      when(mockNewsCubit.state).thenReturn(const NewsState.initial());
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      verify(mockNewsCubit.loadNews()).called(1);
    });

    testWidgets('shows loading indicator when state is loading', 
      (WidgetTester tester) async {
        when(mockNewsCubit.state).thenReturn(const NewsState.loading());
        when(mockNewsCubit.stream).thenAnswer(
          (_) => Stream.fromIterable([const NewsState.loading()]),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (WidgetTester tester) async {
      const errorMessage = 'Network error';
      when(mockNewsCubit.state).thenReturn(const NewsState.error(errorMessage));
      when(mockNewsCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([const NewsState.error(errorMessage)]),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Error: $errorMessage'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      verify(mockNewsCubit.loadNews()).called(2); // Once on init, once on retry
    });

    testWidgets('shows empty state when no articles', (WidgetTester tester) async {
      when(mockNewsCubit.state).thenReturn(
        const NewsState.loaded(articles: [], isLoadingMore: false, hasMoreData: false),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('No articles available'), findsOneWidget);
      expect(find.text('Check back later for new articles'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      verify(mockNewsCubit.loadNews()).called(2); // Once on init, once on refresh
    });

    testWidgets('displays list of articles correctly', (WidgetTester tester) async {
      final articles = [
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

      when(mockNewsCubit.state).thenReturn(
        NewsState.loaded(
          articles: articles,
          isLoadingMore: false,
          hasMoreData: false,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Test Article'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('handles search functionality', (WidgetTester tester) async {
      when(mockNewsCubit.state).thenReturn(
        const NewsState.loaded(
          articles: [],
          isLoadingMore: false,
          hasMoreData: false,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      verify(mockNewsCubit.searchAllArticles('test query')).called(1);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      verify(mockNewsCubit.searchAllArticles('')).called(1);
    });

    testWidgets('handles infinite scroll', (WidgetTester tester) async {
      final articles = List.generate(
        10,
        (i) => NewsArticle(
          id: '$i',
          title: 'Article $i',
          description: 'Description $i',
          author: 'Author',
          publishedAt: DateTime.now(),
          imageUrl: 'test.jpg',
          htmlContent: '<p>Test</p>',
        ),
      );

      when(mockNewsCubit.state).thenReturn(
        NewsState.loaded(
          articles: articles,
          isLoadingMore: false,
          hasMoreData: true,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Scroll to bottom
      await tester.dragUntilVisible(
        find.text('Article 9'),
        find.byType(ListView),
        const Offset(0, -500),
      );
      
      verify(mockNewsCubit.loadMoreArticles()).called(1);
    });

  });
}