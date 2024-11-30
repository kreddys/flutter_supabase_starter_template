import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import 'article_detail_screen.dart';
import '../../domain/entities/news_article.dart';

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
  // Capture the NewsCubit reference before showing the modal
  final newsCubit = context.read<NewsCubit>();
  
  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      print('NewsContent: Building search modal');
      return BlocProvider.value(
        value: newsCubit, // Provide the captured cubit to the modal
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                    newsCubit.searchArticles(value);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildSearchResultItem(BuildContext context, NewsArticle article) {
    print('NewsContent: Building search result item for article: ${article.title}');
    return GestureDetector(
      onTap: () {
        print('NewsContent: Search result item tapped: ${article.title}');
        Navigator.pop(context);
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (article.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  article.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('NewsContent: Error loading image for article: ${article.title}');
                    return const SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(
                        child: Icon(CupertinoIcons.exclamationmark_circle),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  ? const Center(
                      child: Text('No articles found'),
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
  print('NewsContent: Building article card for: ${article.title}'); // Debug print
  return GestureDetector(
    onTap: () {
      print('NewsContent: Article card tapped: ${article.title}'); // Debug print
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
                  print('NewsContent: Error loading image for article: ${article.title}'); // Debug print
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
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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