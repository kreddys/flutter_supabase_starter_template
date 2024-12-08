import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';  // Add this import
import '../../domain/entities/news_article.dart';

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  String? getYouTubeVideoId(String url) {
    RegExp regExp = RegExp(
      r'^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
    );
    if (url.contains('youtu')) {
      Match? match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 2) {
        return match.group(2);
      }
    }
    return null;
  }

  void onTapFunction(BuildContext context, String url) {
    String? videoId = getYouTubeVideoId(url);
    if (videoId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubePlayerScreen(videoId: videoId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: url),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

Widget _buildAuthorsAndTags(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Authors section
        Text(
          'Authors',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: article.authors.map((author) {
            return Chip(
              avatar: author.profileImage != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(author.profileImage!),
                    )
                  : null,
              label: Text(author.name),
              backgroundColor: Theme.of(context).colorScheme.surface,
            );
          }).toList(),
        ),

        if (article.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Tags section
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: article.tags.map((tag) {
              return Chip(
                label: Text(tag.name),
                backgroundColor: Theme.of(context).colorScheme.surface,
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );
}

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
                  Text(
                    _formatDate(article.publishedAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
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
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.3),
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                      "pre, code": Style(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        padding: HtmlPaddings.all(8),
                        margin: Margins.symmetric(vertical: 8),
                        fontFamily: "monospace",
                      ),
                    },
                    extensions: [
                      TagExtension(
                        tagsToExtend: {"iframe"},
                        builder: (extensionContext) {
                          final src = extensionContext.attributes['src'] ?? '';
                          if (src.contains('youtube.com') ||
                              src.contains('youtu.be')) {
                            String? videoId = getYouTubeVideoId(src);
                            if (videoId != null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Container(
                                      width: constraints.maxWidth,
                                      height: constraints.maxWidth * 9 / 16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: YoutubePlayer(
                                          controller:
                                              YoutubePlayerController.fromVideoId(
                                            videoId: videoId,
                                            params: const YoutubePlayerParams(
                                              showControls: true,
                                              showFullscreenButton: true,
                                              mute: false,
                                              playsInline: true,
                                            ),
                                          ),
                                          aspectRatio: 16 / 9,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    onLinkTap: (url, _, __) {
                      if (url != null) {
                        onTapFunction(context, url);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildAuthorsAndTags(context), // Moved to bottom after content
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

// YouTube Player Screen
class YouTubePlayerScreen extends StatefulWidget {
  final String videoId;

  const YouTubePlayerScreen({super.key, required this.videoId});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,                // Start with sound
        loop: false,                // Don't loop the video
        enableJavaScript: true,     // Enable JavaScript
        showVideoAnnotations: false,
        playsInline: true,         // Play inline on iOS
        strictRelatedVideos: true, // Only show related videos from the same channel
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: YoutubePlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
      ),
    );
  }

}

// WebView Screen (unchanged)
class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You can handle loading progress here
          },
          onPageStarted: (String url) {
            // Handle page load start
          },
          onPageFinished: (String url) {
            // Handle page load complete
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource errors
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}