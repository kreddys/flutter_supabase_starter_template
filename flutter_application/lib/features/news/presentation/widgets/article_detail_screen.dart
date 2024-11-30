import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../domain/entities/news_article.dart';
import 'package:flutter/material.dart';

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl.isNotEmpty)
                Image.network(
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'By ${article.author}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(article.publishedAt),
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Html(
  data: article.htmlContent,
  style: {
    "body": Style(
      fontSize: FontSize(15),
      color: CupertinoColors.label,
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
    ),
    "a": Style(
      textDecoration: TextDecoration.none,
      color: CupertinoColors.activeBlue,
    ),
    "u": Style(
      textDecoration: TextDecoration.none,
    ),
    "span": Style(
      textDecoration: TextDecoration.none,
      backgroundColor: Colors.transparent,
    ),
    "p": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
    ),
    "*": Style(
      backgroundColor: Colors.transparent,
      textDecoration: TextDecoration.none,
    ),
  },
  onLinkTap: (url, _, __) {
    // Handle link taps if needed
  },
),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}