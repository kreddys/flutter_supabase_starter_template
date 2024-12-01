import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/font_sizes.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s16,
          ),
          child: Text(
            title.toUpperCase(),
            style: context.theme.textTheme.labelSmall,
          ),
        ),
        Column(
          children: items,
        ),
      ],
    );
  }
}
