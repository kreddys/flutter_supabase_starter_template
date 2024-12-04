import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:amaravati_chamber/features/theme_mode/domain/use_case/get_or_set_initial_theme_mode_use_case.dart';
import 'package:amaravati_chamber/features/theme_mode/domain/use_case/set_theme_mode_id_use_case.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

part 'theme_mode_state.dart';

@injectable
class ThemeModeCubit extends Cubit<ThemeModeState> {
  ThemeModeCubit(
    this._getOrSetInitialThemeModeUseCase,
    this._setThemeModeUseCase,
  ) : super(const ThemeModeState());

  final GetOrSetInitialThemeModeUseCase _getOrSetInitialThemeModeUseCase;
  final SetThemeModeUseCase _setThemeModeUseCase;

  void getCurrentTheme() {
    try {
      AppLogger.debug('Getting current theme');
      var systemThemeModeId = ThemeMode.system.index;

      var themeModeId = _getOrSetInitialThemeModeUseCase.execute(
        GetOrSetInitialThemeModeUseCaseParams(
          currentThemeModeId: systemThemeModeId,
        ),
      );

      AppLogger.info('Theme retrieved: ${ThemeMode.values[themeModeId]}');
      emit(state.copyWith(
        selectedThemeMode: ThemeMode.values[themeModeId],
      ));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to get current theme: $error');
      SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'theme_get_failure',
      );
    }
  }

  void setTheme(int? themeModeIndex) {
    if (themeModeIndex == null) return;

    try {
      AppLogger.info('Setting theme mode: ${state.modes[themeModeIndex]}');
      SentryMonitoring.addBreadcrumb(
        message: 'Theme changed',
        category: 'theme',
        data: {'theme_mode': state.modes[themeModeIndex].toString()},
      );

      _setThemeModeUseCase.execute(SetThemeModeUseCaseParams(
        themeModeIndex: themeModeIndex,
      ));

      emit(state.copyWith(
        selectedThemeMode: state.modes[themeModeIndex],
      ));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to set theme: $error');
      SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'theme_set_failure',
      );
    }
  }
}