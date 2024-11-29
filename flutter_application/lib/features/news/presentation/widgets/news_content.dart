// lib/features/news/presentation/widgets/news_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import '../../../../dependency_injection.dart';
import 'article_detail_screen.dart';

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
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NewsCubit>()..loadNews(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('News'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SearchBar(
                  hintText: 'Search articles...',
                  leading: const Icon(Icons.search),
                  onChanged: (value) {
                    context.read<NewsCubit>().searchArticles(value);
                  },
                ),
              ),
            ),
          ),
          body: BlocBuilder<NewsCubit, NewsState>(
            builder: (context, state) {
              return state.when(
                initial: () => const SizedBox(),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                loaded: (articles, isLoadingMore, hasMoreData) => articles.isEmpty
                    ? const Center(
                        child: Text('No articles found'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: articles.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == articles.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final article = articles[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArticleDetailScreen(
                                      article: article,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (article.imageUrl.isNotEmpty)
                                    Image.network(
                                      article.imageUrl,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article.title,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          article.description,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                error: (message) => Center(
                  child: Text('Error: $message'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}