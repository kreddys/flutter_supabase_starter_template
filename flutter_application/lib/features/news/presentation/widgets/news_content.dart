import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import 'article_detail_screen.dart';
import '../../domain/entities/news_article.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_application/dependency_injection.dart';

class NewsContent extends StatefulWidget {
  const NewsContent({super.key});

  @override
  State<NewsContent> createState() {
    print('NewsContent: Creating State');
    return _NewsContentState();
  }
}

class _NewsContentState extends State<NewsContent> {
  final ScrollController _scrollController = ScrollController();

  String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

  @override
  void initState() {
    print('NewsContent: initState called');
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('NewsContent: Post frame callback - Loading initial news');
      context.read<NewsCubit>().loadNews();
    });
  }

  @override
  void dispose() {
    print('NewsContent: dispose called');
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    print('NewsContent: Scroll event detected');
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      print('NewsContent: Reached scroll threshold, loading more articles');
      context.read<NewsCubit>().loadMoreArticles();
    }
  }

void _showSearchModal(BuildContext context) {
  print('NewsContent: About to show search modal');
  final mainNewsCubit = context.read<NewsCubit>();
  
  // Create a new NewsCubit by getting the repository through dependency injection
  final searchNewsCubit = getIt<NewsCubit>();  // Use your DI container
  
  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      print('NewsContent: Building search modal');
      return BlocProvider(
        create: (_) => searchNewsCubit,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: CupertinoColors.separator,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoSearchTextField(
                  onChanged: (value) {
                    print('NewsContent: Search query: $value');
                    searchNewsCubit.searchAllArticles(value);
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<NewsCubit, NewsState>(
                  builder: (context, state) {
                    return state.when(
                      initial: () => const SizedBox(),
                      loading: () => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      loaded: (articles, isLoadingMore, hasMoreData) {
                        if (articles.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.doc_text_search,
                                  size: 48,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No articles found',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.label,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try adjusting your search terms\nor check back later',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: articles
                              .map((article) => _buildSearchResultItem(context, article))
                              .toList(),
                        );
                      },
                      error: (message) => Center(
                        child: Text('Error: $message'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    // Dispose the search cubit when the modal is closed
    searchNewsCubit.close();
  });
}


Widget _buildSearchResultItem(BuildContext context, NewsArticle article) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(context);
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ArticleDetailScreen(article: article),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                article.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Html(
                  data: article.title,
                  style: {
                    "body": Style(
                      fontSize: FontSize(14),
                      color: CupertinoColors.label,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontWeight: FontWeight.w500,
                      backgroundColor: CupertinoColors.systemBackground,
                      maxLines: 2,
                    ),
                    "span": Style(
                      textDecoration: TextDecoration.none,
                      backgroundColor: CupertinoColors.systemBackground,
                    ),
                    "*": Style(
                      backgroundColor: CupertinoColors.systemBackground,
                      textDecoration: TextDecoration.none,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(article.publishedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    print('NewsContent: Building main widget');
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('News'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.search),
          onPressed: () => _showSearchModal(context),
        ),
      ),
      child: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          print('NewsContent: Building main content for state: ${state.runtimeType}');
          return state.when(
            initial: () {
              print('NewsContent: Main state - Initial');
              return const SizedBox();
            },
            loading: () {
              print('NewsContent: Main state - Loading');
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            },
            loaded: (articles, isLoadingMore, hasMoreData) {
              print('NewsContent: Main state - Loaded with ${articles.length} articles');
              return articles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.news,
                            size: 48,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No articles available',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check back later for new articles',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton(
                            child: const Text('Refresh'),
                            onPressed: () {
                              context.read<NewsCubit>().loadNews();
                            },
                          ),
                        ],
                      ),
                    )
                  : _buildMainContent(articles, isLoadingMore, hasMoreData);
            },
            error: (message) {
              print('NewsContent: Main state - Error: $message');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $message'),
                    CupertinoButton(
                      child: const Text('Retry'),
                      onPressed: () {
                        print('NewsContent: Retry button pressed');
                        context.read<NewsCubit>().loadNews();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMainContent(List<NewsArticle> articles, bool isLoadingMore, bool hasMoreData) {
    print('NewsContent: Building main content with ${articles.length} articles');
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            print('NewsContent: Pull-to-refresh triggered');
            await context.read<NewsCubit>().loadNews();
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == articles.length) {
                  print('NewsContent: Showing loading indicator at the bottom');
                  return isLoadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CupertinoActivityIndicator(),
                          ),
                        )
                      : const SizedBox();
                }
                print('NewsContent: Building article card at index $index');
                return _buildArticleCard(context, articles[index]);
              },
              childCount: articles.length + (hasMoreData ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }

Widget _buildArticleCard(BuildContext context, NewsArticle article) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ArticleDetailScreen(article: article),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Image.network(
                article.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(CupertinoIcons.exclamationmark_circle),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Html(
                  data: article.title,
                  style: {
                    "body": Style(
                      fontSize: FontSize(17),
                      color: CupertinoColors.label,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontWeight: FontWeight.w600,
                      backgroundColor: CupertinoColors.systemBackground,
                    ),
                    "span": Style(
                      textDecoration: TextDecoration.none,
                      backgroundColor: CupertinoColors.systemBackground,
                    ),
                    "*": Style(
                      backgroundColor: CupertinoColors.systemBackground,
                      textDecoration: TextDecoration.none,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                  },
                ),
                const SizedBox(height: 4), // Reduced from 8 to 4
                Html(
                  data: article.description,
                  style: {
                    "body": Style(
                      fontSize: FontSize(15),
                      color: CupertinoColors.secondaryLabel,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontWeight: FontWeight.normal,
                      maxLines: 3,
                      textOverflow: TextOverflow.ellipsis,
                      backgroundColor: CupertinoColors.systemBackground,
                    ),
                    "span": Style(
                      textDecoration: TextDecoration.none,
                      backgroundColor: CupertinoColors.systemBackground,
                    ),
                    "*": Style(
                      backgroundColor: CupertinoColors.systemBackground,
                      textDecoration: TextDecoration.none,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


}