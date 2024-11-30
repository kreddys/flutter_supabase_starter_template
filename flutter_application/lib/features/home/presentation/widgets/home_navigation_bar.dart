import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';

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
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: (index) => context.read<BottomNavigationBarCubit>().switchTab(index),
      activeColor: CupertinoColors.activeBlue, // iOS default active color
      items: tabs
          .map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ))
          .toList(),
    );
  }
}