import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:amaravati_chamber/features/home/presentation/widgets/welcome_content.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:amaravati_chamber/features/news/presentation/widgets/news_content.dart';
import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/monitoring/sentry_monitoring.dart';
import 'package:amaravati_chamber/features/business_listings/presentation/pages/business_listings_page.dart';
import './tab_item.dart';

part 'bottom_navigation_bar_state.dart';

@injectable
class BottomNavigationBarCubit extends Cubit<BottomNavigationBarState> {
  BottomNavigationBarCubit()
      : super(
          BottomNavigationBarState(),
        );

  void switchTab(int index) {
    AppLogger.info('Tab switched to index: $index');
    SentryMonitoring.addBreadcrumb(
      message: 'Tab switched',
      category: 'navigation',
      data: {
        'tab_index': index,
        'tab_name': state.tabs[index].label,
      },
    );
    
    emit(state.copyWith(selectedIndex: index));
  }

  void toggleSecondTab() {
    emit(state.copyWith(isNewsSelected: !state.isNewsSelected));
  }
}