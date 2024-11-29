import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_cubit.dart';
import '../bloc/news_state.dart';
import '../../../../dependency_injection.dart';

class NewsContent extends StatelessWidget {
  const NewsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NewsCubit>()..loadNews(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('News'),
        ),
        body: BlocBuilder<NewsCubit, NewsState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox(),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              loaded: (articles) => ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ListTile(
                      title: Text(
                        article.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'By ${article.author}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      leading: const Icon(Icons.newspaper),
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
    );
  }
}