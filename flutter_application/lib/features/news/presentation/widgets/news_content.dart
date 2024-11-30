import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import '../../../../dependency_injection.dart';
import 'article_detail_screen.dart';
import '../../domain/entities/news_article.dart';

class NewsContent extends StatefulWidget {
  const NewsContent({super.key});

  @override
  State<NewsContent> createState() => _NewsContentState();
}

class _NewsContentState extends State<NewsContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsCubit>().loadNews();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NewsCubit>().loadMoreArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('News'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.search),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => Container(
                height: 60,
                color: CupertinoColors.systemBackground,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CupertinoSearchTextField(
                      onChanged: (value) {
                        context.read<NewsCubit>().searchArticles(value);
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      child: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox(),
            loading: () => const Center(
              child: CupertinoActivityIndicator(),
            ),
            loaded: (articles, isLoadingMore, hasMoreData) => articles.isEmpty
                ? const Center(
                    child: Text('No articles found'),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () async {
                          await context.read<NewsCubit>().loadNews();
                        },
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == articles.length) {
                                return isLoadingMore
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CupertinoActivityIndicator(),
                                        ),
                                      )
                                    : const SizedBox();
                              }

                              final article = articles[index];
                              return _buildArticleCard(context, article);
                            },
                            childCount: articles.length + (hasMoreData ? 1 : 0),
                          ),
                        ),
                      ),
                    ],
                  ),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $message'),
                  CupertinoButton(
                    child: const Text('Retry'),
                    onPressed: () {
                      context.read<NewsCubit>().loadNews();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
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