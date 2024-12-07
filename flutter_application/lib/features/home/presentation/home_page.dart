import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import 'package:amaravati_chamber/features/home/presentation/bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart';
import 'package:amaravati_chamber/features/home/presentation/widgets/home_navigation_bar.dart';
import '../../news/presentation/bloc/news_cubit.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building HomePage');
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            AppLogger.debug('Creating BottomNavigationBarCubit');
            return getIt<BottomNavigationBarCubit>();
          },
        ),
        BlocProvider(
          create: (context) {
            AppLogger.debug('Creating NewsCubit');
            return getIt<NewsCubit>();
          },
        ),
      ],
      child: BlocBuilder<BottomNavigationBarCubit, BottomNavigationBarState>(
        buildWhen: (previous, current) {
          final changed = current.selectedIndex != previous.selectedIndex;
          if (changed) {
            AppLogger.info(
              'Navigation changed from ${previous.selectedIndex} to ${current.selectedIndex}'
            );
            SentryMonitoring.addBreadcrumb(
              message: 'Tab navigation changed to ${current.selectedIndex}',
              category: 'navigation',
            );
          }
          return changed;
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: GestureDetector(
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (details.primaryVelocity == null) return;
                  
                  final cubit = context.read<BottomNavigationBarCubit>();
                  final currentIndex = state.selectedIndex;

                  // Swipe from left to right (positive velocity)
                  if (details.primaryVelocity! > 0) {
                    if (currentIndex == 2) { // If on settings page
                      cubit.switchTab(1); // Go to middle page
                    } else if (currentIndex == 1) { // If on middle page
                      cubit.switchTab(0); // Go to home page
                    }
                  }
                  // Swipe from right to left (negative velocity)
                  else if (details.primaryVelocity! < 0) {
                    if (currentIndex == 0) { // If on home page
                      cubit.switchTab(1); // Go to middle page
                    } else if (currentIndex == 1) { // If on middle page
                      cubit.switchTab(2); // Go to settings page
                    }
                  }
                },
                child: Stack(
                  children: [
                    state.tabs[state.selectedIndex].content,
                  ],
                ),
              ),
            ),
            bottomNavigationBar: HomeNavigationBar(
              selectedIndex: state.selectedIndex,
              tabs: state.tabs,
            ),
          );
        },
      ),
    );
  }
}