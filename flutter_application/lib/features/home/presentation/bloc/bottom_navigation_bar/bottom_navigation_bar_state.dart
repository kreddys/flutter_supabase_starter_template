part of 'bottom_navigation_bar_cubit.dart';

@immutable
class BottomNavigationBarState extends Equatable {
  BottomNavigationBarState({
    this.selectedIndex = 0,
  });

  final int selectedIndex;
  final tabs = <TabItem>[
    const TabItem(
      label: "Home",
      icon: CupertinoIcons.home,
      tooltip: "Home",
      content: WelcomeContent(),
    ),
    const TabItem(
      tooltip: 'News',
      label: 'News',
      icon: CupertinoIcons.news,
      content: NewsContent(),
    ),    
    const TabItem(
      label: "Settings",
      icon: CupertinoIcons.settings,
      tooltip: "Settings",
      content: SettingsPage(),
    ),
  ];

  BottomNavigationBarState copyWith({int? selectedIndex}) {
    return BottomNavigationBarState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  List<Object?> get props => [
        selectedIndex,
        tabs,
      ];
}

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