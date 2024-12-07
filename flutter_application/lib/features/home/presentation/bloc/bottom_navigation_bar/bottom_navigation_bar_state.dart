part of 'bottom_navigation_bar_cubit.dart';

@immutable
class BottomNavigationBarState extends Equatable {
  BottomNavigationBarState({
    this.selectedIndex = 0,
    this.isNewsSelected = true,  // Add this for dynamic second tab
  });

  final int selectedIndex;
  final bool isNewsSelected;

  List<TabItem> get tabs => [
    const TabItem(
      label: "Home",
      icon: Icons.home,
      tooltip: "Home",
      content: WelcomeContent(),
    ),
    TabItem(
      tooltip: isNewsSelected ? 'News' : 'Business',
      label: isNewsSelected ? 'News' : 'Business',
      icon: isNewsSelected ? Icons.newspaper : Icons.business,
      content: isNewsSelected 
          ? const NewsContent()
          : const BusinessListingsPage(),
    ),    
    const TabItem(
      label: "Settings",
      icon: Icons.settings,
      tooltip: "Settings",
      content: SettingsPage(),
    ),
  ];

  BottomNavigationBarState copyWith({
    int? selectedIndex,
    bool? isNewsSelected,
  }) {
    return BottomNavigationBarState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isNewsSelected: isNewsSelected ?? this.isNewsSelected,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, isNewsSelected, tabs];
}