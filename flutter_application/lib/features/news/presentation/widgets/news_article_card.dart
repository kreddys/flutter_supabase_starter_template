import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../domain/entities/news_article.dart';
import '../../../../core/widgets/vote_buttons.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';
import '../widgets/article_detail_screen.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import '../../../../core/widgets/content_card.dart';

class NewsArticleCard extends StatelessWidget {
  final NewsArticle article;
  final Function(String, VoteType?) onVote;

  const NewsArticleCard({
    super.key,
    required this.article,
    required this.onVote,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      title: article.title,
      description: article.description,
      imageUrl: article.imageUrl,
      date: article.publishedAt,
      tags: [],
      onTap: () => _navigateToArticleDetail(context),
      footer: VoteButtons(
        entityId: article.id,
        userVote: article.userVote,
        upvotes: article.upvotes,
        downvotes: article.downvotes,
        onVote: (voteType) => onVote(article.id, voteType),
      ),
    );
  }

  void _navigateToArticleDetail(BuildContext context) {
    AppLogger.info('User opened article: ${article.id}');
    SentryMonitoring.addBreadcrumb(
      message: 'Article opened',
      category: 'user_action',
      data: {'article_id': article.id},
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(article: article),
      ),
    );
  }

  Widget _buildArticleImage(BuildContext context) {
    if (article.imageUrl.isEmpty) return const SizedBox();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Image.network(
        article.imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          AppLogger.warning('Failed to load article image');
          SentryMonitoring.captureException(error, stackTrace);
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
    );
  }

  Widget _buildArticleCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArticleTitle(context),
          const SizedBox(height: 4),
          _buildArticleDescription(context),
          const SizedBox(height: 8),
          _buildArticleFooter(context),
        ],
      ),
    );
  }

  Widget _buildArticleTitle(BuildContext context) {
    return Html(
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
    );
  }

  Widget _buildArticleDescription(BuildContext context) {
    return Html(
      data: article.description,
      style: {
        "body": Style(
          fontSize: FontSize(15),
          color: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.color
              ?.withOpacity(0.7),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          maxLines: 3,
          textOverflow: TextOverflow.ellipsis,
        ),
      },
    );
  }

  Widget _buildTags(BuildContext context) {
    if (article.tags.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: article.tags.map((tag) {
        return Chip(
          label: Text(
            tag.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildArticleFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuthors(context),
              Text(
                _formatDate(article.publishedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
        VoteButtons(
          entityId: article.id,
          userVote: article.userVote,
          upvotes: article.upvotes,
          downvotes: article.downvotes,
          onVote: (voteType) => onVote(article.id, voteType),
        ),
      ],
    );
  }

  Widget _buildAuthors(BuildContext context) {
    final authorNames = article.authors.map((author) => author.name).join(', ');
    return Text(
      authorNames,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withOpacity(0.7),
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}