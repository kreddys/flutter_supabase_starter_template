import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import './news_article_card.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import '../../domain/entities/news_article.dart';

class NewsContent extends StatefulWidget {
  const NewsContent({super.key});

  @override
  State<NewsContent> createState() => _NewsContentState();
}

class _TagFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          final newsCubit = context.read<NewsCubit>();
          final selectedTag = newsCubit.selectedTag;
          final tags = newsCubit.allTags;
          
          return Row(
            children: tags.map((tag) {
              final isSelected = selectedTag == tag;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      // Clear search when selecting a new tag
                      if (tag == 'All') {
                        context.read<NewsCubit>().searchAllArticles('');
                      }
                      context.read<NewsCubit>().filterByTag(tag);
                    }
                  },
                  backgroundColor: isSelected 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).chipTheme.backgroundColor,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _NewsContentState extends State<NewsContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppLogger.debug('Initializing NewsContent widget');
    SentryMonitoring.addBreadcrumb(
      message: 'NewsContent widget initialized',
      category: 'widget_lifecycle',
    );
    
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('Loading initial news articles');
      context.read<NewsCubit>().loadNews();
    });
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing NewsContent widget');
    SentryMonitoring.addBreadcrumb(
      message: 'NewsContent widget disposed',
      category: 'widget_lifecycle',
    );
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      AppLogger.debug('Loading more articles - reached scroll threshold');
      SentryMonitoring.addBreadcrumb(
        message: 'Loading more articles on scroll',
        category: 'infinite_scroll',
        data: {
          'scrollPosition': _scrollController.position.pixels,
          'maxScrollExtent': _scrollController.position.maxScrollExtent,
        },
      );
      context.read<NewsCubit>().loadMoreArticles();
    }
  }

  void _toggleSearch() {
    AppLogger.info('Toggling search state: ${!_isSearching}');
    SentryMonitoring.addBreadcrumb(
      message: 'Search toggled',
      category: 'search',
      data: {'newSearchState': !_isSearching},
    );
    
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        AppLogger.debug('Clearing search and reloading news');
        _searchController.clear();
        context.read<NewsCubit>().loadNews();
      }
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(context),
    body: Column(
      children: [
        if (!_isSearching) _TagFilter(),
        if (!_isSearching) const SizedBox(height: 8.0),
        Expanded(
          child: _buildBody(context),
        ),
      ],
    ),
  );
}

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _toggleSearch,
            )
          : null,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search articles...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              onChanged: (value) {
                AppLogger.debug('Search query changed: $value');
                SentryMonitoring.addBreadcrumb(
                  message: 'Search query entered',
                  category: 'search',
                  data: {'query': value},
                );
                context.read<NewsCubit>().searchAllArticles(value);
              },
            )
          : Text(
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
            _isSearching ? Icons.clear : Icons.search,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: _isSearching
              ? () {
                  AppLogger.debug('Clearing search query');
                  SentryMonitoring.addBreadcrumb(
                    message: 'Search cleared',
                    category: 'search',
                  );
                  _searchController.clear();
                  context.read<NewsCubit>().searchAllArticles('');
                }
              : _toggleSearch,
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
              hasMoreData,
            );
          },
          error: (message) => _buildErrorState(context, message),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    AppLogger.info('Showing empty state');
    SentryMonitoring.addBreadcrumb(
      message: 'Empty state displayed',
      category: 'ui_state',
    );
    
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
            onPressed: () {
              AppLogger.info('Refresh button clicked in empty state');
              SentryMonitoring.addBreadcrumb(
                message: 'Empty state refresh clicked',
                category: 'user_action',
              );
              context.read<NewsCubit>().loadNews();
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    AppLogger.error('Error loading news: $message');
    SentryMonitoring.addBreadcrumb(
      message: 'Error state displayed',
      category: 'error',
      data: {'errorMessage': message},
    );
    
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
              SentryMonitoring.addBreadcrumb(
                message: 'Error state retry clicked',
                category: 'user_action',
              );
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
    bool hasMoreData,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        AppLogger.info('Manual refresh triggered');
        SentryMonitoring.addBreadcrumb(
          message: 'Manual refresh',
          category: 'user_action',
        );
        return context.read<NewsCubit>().loadNews();
      },
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
                AppLogger.info('Vote action triggered: $articleId, type: $voteType');
                SentryMonitoring.addBreadcrumb(
                  message: 'Article vote',
                  category: 'user_action',
                  data: {
                    'articleId': articleId,
                    'voteType': voteType.toString(),
                  },
                );
                
                await context.read<NewsCubit>().updateVoteOnly(
                      articleId: articleId,
                      voteType: voteType,
                    );
              } catch (error, stackTrace) {
                AppLogger.error('Error while voting: $error');
                await SentryMonitoring.captureException(
                  error,
                  stackTrace,
                  tagValue: 'vote_failure',
                );
              }
            },
          );
        },
      ),
    );
  }
}