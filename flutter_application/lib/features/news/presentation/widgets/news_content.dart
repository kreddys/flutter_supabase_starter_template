// lib/features/news/presentation/widgets/news_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import './news_article_card.dart';
import './news_search_modal.dart';
import '../../../../core/logging/app_logger.dart';
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
    AppLogger.debug('Initializing NewsContent widget');
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('Loading initial news articles');
      context.read<NewsCubit>().loadNews();
    });
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing NewsContent widget');
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      AppLogger.debug('Loading more articles - reached scroll threshold');
      context.read<NewsCubit>().loadMoreArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'News',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => _showSearchModal(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox(),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (articles, isLoadingMore, hasMoreData) {
            if (articles.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildNewsList(
              context, 
              articles, 
              isLoadingMore, 
              hasMoreData
            );
          },
          error: (message) => _buildErrorState(context, message),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No articles available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new articles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<NewsCubit>().loadNews(),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    AppLogger.error('Error loading news: $message');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error: $message',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              AppLogger.info('User retrying news load after error');
              context.read<NewsCubit>().loadNews();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(
    BuildContext context, 
    List<NewsArticle> articles, 
    bool isLoadingMore, 
    bool hasMoreData
  ) {
    return RefreshIndicator(
      onRefresh: () => context.read<NewsCubit>().loadNews(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: articles.length + (hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == articles.length) {
            return isLoadingMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox();
          }
          return NewsArticleCard(
            article: articles[index],
            onVote: (articleId, voteType) async {
              try {
                await context.read<NewsCubit>().updateVoteAndRefresh(
                  articleId: articleId,
                  voteType: voteType,
                );
              } catch (error) {
                AppLogger.error('Error while voting: $error');
              }
            },
          );
        },
      ),
    );
  }

void _showSearchModal(BuildContext context) {
  AppLogger.debug('Opening search modal');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => BlocProvider.value(
      // Pass the existing NewsCubit instance from the parent context
      value: context.read<NewsCubit>(),
      child: NewsSearchModal(
        searchNewsCubit: context.read<NewsCubit>(),
      ),
    ),
  );
}
}