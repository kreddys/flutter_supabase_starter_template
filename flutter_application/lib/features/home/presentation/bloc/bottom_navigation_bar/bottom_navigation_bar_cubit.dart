import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:amaravati_chamber/features/home/presentation/widgets/welcome_content.dart';
import 'package:amaravati_chamber/features/settings/presentation/page/settings_page.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:amaravati_chamber/features/news/presentation/widgets/news_content.dart';

part 'bottom_navigation_bar_state.dart';

@injectable
class BottomNavigationBarCubit extends Cubit<BottomNavigationBarState> {
  BottomNavigationBarCubit()
      : super(
          BottomNavigationBarState(),
        );

  void switchTab(int index) {
    emit(state.copyWith(
      selectedIndex: index,
    ));
  }
}
