import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import 'package:amaravati_chamber/features/home/presentation/bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';
import 'package:amaravati_chamber/features/home/presentation/widgets/home_navigation_bar.dart';
import '../../news/presentation/bloc/news_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<BottomNavigationBarCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<NewsCubit>(),
        ),
      ],
      child: BlocBuilder<BottomNavigationBarCubit, BottomNavigationBarState>(
        buildWhen: (previous, current) => 
            current.selectedIndex != previous.selectedIndex,
        builder: (context, state) {
          return CupertinoPageScaffold(
            child: SafeArea(
              child: Stack(
                children: [
                  state.tabs[state.selectedIndex].content,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: HomeNavigationBar(
                      selectedIndex: state.selectedIndex,
                      tabs: state.tabs,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}