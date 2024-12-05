// lib/features/news/presentation/widgets/news_search_article_card.dart

import 'package:flutter/material.dart';
import '../../domain/entities/news_article.dart';
import '../../../../core/voting/domain/repositories/i_voting_repository.dart';

class NewsSearchArticleCard extends StatelessWidget {
  final NewsArticle article;
  final Future<void> Function(String, VoteType?) onVote;

  const NewsSearchArticleCard({
    super.key,
    required this.article,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        title: Text(
          article.title,
          style: Theme.of(context).textTheme.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          article.description,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_upward,
                color: article.userVote == VoteType.upvote
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () => onVote(article.id, 
                article.userVote == VoteType.upvote ? null : VoteType.upvote),
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_downward,
                color: article.userVote == VoteType.downvote
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              onPressed: () => onVote(article.id,
                article.userVote == VoteType.downvote ? null : VoteType.downvote),
            ),
          ],
        ),
      ),
    );
  }
}