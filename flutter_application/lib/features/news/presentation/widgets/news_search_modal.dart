// lib/features/news/presentation/widgets/news_search_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import '../../domain/entities/news_article.dart';
import '../../../../core/logging/app_logger.dart';
import './news_search_article_card.dart';

class NewsSearchModal extends StatelessWidget {
  final NewsCubit searchNewsCubit;

  const NewsSearchModal({
    super.key,
    required this.searchNewsCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          _buildDragHandle(context),
          _buildSearchField(context),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
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
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        onChanged: (value) {
          AppLogger.debug('Search query changed: $value');
          searchNewsCubit.searchAllArticles(value);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox(),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (articles, _, __) => _buildSearchResultsList(context, articles),
            error: (message) => Center(
              child: Text(
                'Error: $message',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResultsList(BuildContext context, List<NewsArticle> articles) {
    if (articles.isEmpty) {
      return _buildEmptySearchResults(context);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: articles.length,
      itemBuilder: (context, index) => NewsSearchArticleCard(
        article: articles[index],
        onVote: (articleId, voteType) async {
          await searchNewsCubit.updateVoteAndRefresh(
            articleId: articleId,
            voteType: voteType,
          );
        },
      ),
    );
  }

  Widget _buildEmptySearchResults(BuildContext context) {
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
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}