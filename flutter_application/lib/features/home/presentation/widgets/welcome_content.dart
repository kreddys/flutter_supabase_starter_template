import 'package:flutter/cupertino.dart';
import 'package:flutter_application/core/constants/spacings.dart';
import 'package:flutter_application/core/extensions/build_context_extensions.dart';

class WelcomeContent extends StatelessWidget {
  const WelcomeContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Amaravati News',
          style: context.textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.none,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WelcomeBanner(),
                const SizedBox(height: Spacing.s16),
                _FeaturedCategories(),
                const SizedBox(height: Spacing.s16),
                _QuickLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Amaravati News',
            style: context.textTheme.headlineSmall?.copyWith(
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: Spacing.s8),
          Text(
            'Your trusted source for local news and updates from Amaravati, Andhra Pradesh',
            style: context.textTheme.bodyMedium?.copyWith(
              color: CupertinoColors.secondaryLabel,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCategories extends StatelessWidget {
  final List<Map<String, String>> categories = const [
    {'title': 'Local News', 'icon': '📰'},
    {'title': 'Government', 'icon': '🏛'},
    {'title': 'Development', 'icon': '🏗'},
    {'title': 'Education', 'icon': '📚'},
    {'title': 'Culture', 'icon': '🎭'},
    {'title': 'Events', 'icon': '📅'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: context.textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: Spacing.s8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categories[index]['icon']!,
                    style: const TextStyle(
                      fontSize: 24,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categories[index]['title']!,
                    style: context.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  final List<Map<String, dynamic>> links = const [
    {
      'title': 'Latest Updates',
      'icon': CupertinoIcons.news,
      'description': 'Most recent news from Amaravati'
    },
    {
      'title': 'Emergency Contacts',
      'icon': CupertinoIcons.phone,
      'description': 'Important contact numbers'
    },
    {
      'title': 'Public Services',
      'icon': CupertinoIcons.building_2_fill,
      'description': 'Government services information'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: context.textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: Spacing.s8),
        ...links.map((link) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.all(12),
                onPressed: () {
                  // Handle navigation
                },
                child: Row(
                  children: [
                    Icon(link['icon'] as IconData),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link['title'] as String,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            link['description'] as String,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: CupertinoColors.secondaryLabel,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}