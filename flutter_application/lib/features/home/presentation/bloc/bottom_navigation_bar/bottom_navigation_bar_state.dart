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
  const TabItem(
    label: "News",
    icon: Icons.newspaper,
    tooltip: "News",
    content: NewsContent(),
  ),    
  const TabItem(
    label: "Business",
    icon: Icons.business,
    tooltip: "Business",
    content: BusinessListingsPage(),
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