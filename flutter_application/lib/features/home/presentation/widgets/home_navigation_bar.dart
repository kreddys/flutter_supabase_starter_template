// home_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';
import '../bloc/bottom_navigation_bar/tab_item.dart';

class HomeNavigationBar extends StatelessWidget {
  const HomeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
  });

  final int selectedIndex;
  final List<TabItem> tabs;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => context.read<BottomNavigationBarCubit>().switchTab(index),
      items: tabs
          .map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ))
          .toList(),
    );
  }
}