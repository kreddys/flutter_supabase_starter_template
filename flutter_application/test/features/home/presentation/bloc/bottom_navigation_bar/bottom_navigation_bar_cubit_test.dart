// bottom_navigation_bar_cubit_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:amaravati_chamber/features/home/presentation/bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';

void main() {
  late BottomNavigationBarCubit bottomNavigationBarCubit;

  setUp(() {
    bottomNavigationBarCubit = BottomNavigationBarCubit();
  });

  tearDown(() {
    bottomNavigationBarCubit.close();
  });

  test('initial state should have selectedIndex as 0', () {
    expect(bottomNavigationBarCubit.state.selectedIndex, 0);
  });

  test('should have correct number of tabs', () {
    expect(bottomNavigationBarCubit.state.tabs.length, 3);
  });

  test('tabs should have correct labels', () {
    final tabs = bottomNavigationBarCubit.state.tabs;
    expect(tabs[0].label, 'Home');
    expect(tabs[1].label, 'News');
    expect(tabs[2].label, 'Settings');
  });

  test('switchTab should update selectedIndex', () {
    bottomNavigationBarCubit.switchTab(1);
    expect(bottomNavigationBarCubit.state.selectedIndex, 1);

    bottomNavigationBarCubit.switchTab(2);
    expect(bottomNavigationBarCubit.state.selectedIndex, 2);
  });

  test('state should be equatable', () {
    final state1 = BottomNavigationBarState(selectedIndex: 0);
    final state2 = BottomNavigationBarState(selectedIndex: 0);
    final state3 = BottomNavigationBarState(selectedIndex: 1);

    expect(state1 == state2, true);
    expect(state1 == state3, false);
  });
}