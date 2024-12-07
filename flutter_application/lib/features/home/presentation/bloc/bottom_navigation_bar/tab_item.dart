// tab_item.dart
import 'package:flutter/material.dart';

class TabItem {
  const TabItem({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.content,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final Widget content;
}