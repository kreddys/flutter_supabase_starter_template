import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../domain/entities/news_article.dart';

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        middle: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CupertinoColors.label,
            backgroundColor: CupertinoColors.systemBackground,
            decoration: TextDecoration.none,
          )
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
                          fontWeight: FontWeight.normal, // Add this to ensure normal weight
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
                          backgroundColor: CupertinoColors.systemBackground, // Changed to Cupertino color
                        ),
                        "p": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontWeight: FontWeight.normal, // Add this to ensure normal weight
                        ),
                        "h1, h2, h3, h4, h5, h6": Style(
                          backgroundColor: CupertinoColors.systemBackground,
                          textDecoration: TextDecoration.none,
                          fontWeight: FontWeight.bold, // Keep headers bold
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        "*": Style(
                          backgroundColor: CupertinoColors.systemBackground,
                          textDecoration: TextDecoration.none,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
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