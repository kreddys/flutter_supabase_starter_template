import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import 'article_detail_screen.dart';
import '../../domain/entities/news_article.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import '../../../../core/widgets/vote_buttons.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';

class NewsContent extends StatefulWidget {
  const NewsContent({super.key});

  @override
  State<NewsContent> createState() => _NewsContentState();
}

class _NewsContentState extends State<NewsContent> {
  final ScrollController _scrollController = ScrollController();

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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

  void _showSearchModal(BuildContext context) {
    final searchNewsCubit = getIt<NewsCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return BlocProvider(
          create: (_) => searchNewsCubit,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    onChanged: (value) {
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
                          child: CircularProgressIndicator(),
                        ),
                        loaded: (articles, isLoadingMore, hasMoreData) {
                          if (articles.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No articles found',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try different search terms',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
                          child: Text(
                            'Error: $message',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
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
    );
  }

  Widget _buildSearchResultItem(BuildContext context, NewsArticle article) {
    if (article.title.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListTile(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      leading: article.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                article.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.error,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            )
          : null,
      title: Text(
        article.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: article.author.isNotEmpty || article.publishedAt != null
          ? Text(
              [
                if (article.author.isNotEmpty) 'By ${article.author}',
                if (article.publishedAt != null) _formatDate(article.publishedAt),
              ].join(' • '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Amaravati News',
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
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox(),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            loaded: (articles, isLoadingMore, hasMoreData) {
              if (articles.isEmpty) {
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
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<NewsCubit>().loadNews();
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
                    return _buildArticleCard(context, articles[index]);
                  },
                ),
              );
            },
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $message',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<NewsCubit>().loadNews(),
                    child: const Text('Retry'),
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
  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: Theme.of(context).dividerColor,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                article.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Center(
                      child: Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  },
                ),
                const SizedBox(height: 4),
                Html(
                  data: article.description,
                  style: {
                    "body": Style(
                      fontSize: FontSize(15),
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      maxLines: 3,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${article.author} • ${_formatDate(article.publishedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    ),
                    VoteButtons(
                      entityId: article.id,
                      userVote: article.userVote == 1 ? true : article.userVote == -1 ? false : null,
                      upvotes: article.upvotes,
                      downvotes: article.downvotes,
                      onVote: (bool? vote) {
                        context.read<NewsCubit>().updateVote(
                          articleId: article.id, 
                          voteType: vote == null ? null : vote ? VoteType.upvote : VoteType.downvote,
                        );
                      },
                    ),
                  ],
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