import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/news_article.dart';
import 'package:html/dom.dart' as dom;

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl.isNotEmpty)
                Hero(
                  tag: article.id,
                  child: Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
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
                          fontSize: FontSize(24),
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontWeight: FontWeight.bold,
                          lineHeight: LineHeight(1.4),
                        ),
                        "p": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        "*": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          textDecoration: TextDecoration.none,
                        ),
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'By ${article.author}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                          ),
                        ),
                        Text(
                          _formatDate(article.publishedAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Html(
                      data: article.htmlContent,
                      style: {
                        "body": Style(
                          fontSize: FontSize(16),
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          lineHeight: LineHeight(1.8),
                        ),
                        "p": Style(
                          margin: Margins.only(bottom: 16),
                          padding: HtmlPaddings.zero,
                        ),
                        "a": Style(
                          color: Theme.of(context).colorScheme.primary,
                          textDecoration: TextDecoration.underline,
                        ),
                        "img": Style(
                          width: Width(MediaQuery.of(context).size.width - 32),
                          alignment: Alignment.center,
                          margin: Margins.symmetric(vertical: 16),
                        ),
                        "h1": Style(
                          fontSize: FontSize(24),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 32, bottom: 16),
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          lineHeight: LineHeight(1.4),
                        ),
                        "h2": Style(
                          fontSize: FontSize(20),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 28, bottom: 14),
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          lineHeight: LineHeight(1.4),
                        ),
                        "h3": Style(
                          fontSize: FontSize(18),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 24, bottom: 12),
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          lineHeight: LineHeight(1.4),
                        ),
                        "ul, ol": Style(
                          margin: Margins.only(bottom: 16, left: 20),
                          padding: HtmlPaddings.zero,
                        ),
                        "li": Style(
                          margin: Margins.only(bottom: 8),
                          lineHeight: LineHeight(1.6),
                        ),
                        "blockquote": Style(
                          margin: Margins.symmetric(vertical: 16, horizontal: 16),
                          padding: HtmlPaddings.all(16),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 4,
                            ),
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                        "pre, code": Style(
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          padding: HtmlPaddings.all(8),
                          margin: Margins.symmetric(vertical: 8),
                          fontFamily: "monospace",
                        ),
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