import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ContentCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime? date;
  final List<String> tags;
  final VoidCallback onTap;
  final Widget? footer;

  const ContentCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.date,
    required this.tags,
    required this.onTap,
    this.footer,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
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
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Html(
                    data: title,
                    style: {
                      "body": Style(
                        fontSize: FontSize(17),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    },
                  ),
                  const SizedBox(height: 4),
                  Html(
                    data: description,
                    style: {
                      "body": Style(
                        fontSize: FontSize(15),
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        maxLines: 3,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    },
                  ),
                  const SizedBox(height: 8),
                  if (tags.isNotEmpty) _buildTags(context),
                  if (tags.isNotEmpty) const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (date != null) // Only show date text if date is not null
                        Text(
                          _formatDate(date!), // Use ! operator since we know date is not null here
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                        ),
                      if (footer != null) footer!,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) {
        return Chip(
          label: Text(
            tag,
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
}