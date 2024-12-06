import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:amaravati_chamber/features/theme_mode/domain/use_case/get_or_set_initial_theme_mode_use_case.dart';
import 'package:amaravati_chamber/features/theme_mode/domain/use_case/set_theme_mode_id_use_case.dart';
import 'package:amaravati_chamber/features/theme_mode/presentation/bloc/theme_mode_cubit.dart';

import 'theme_mode_cubit_test.mocks.dart';

@GenerateMocks([
  GetOrSetInitialThemeModeUseCase,
  SetThemeModeUseCase,
])
void main() {
  late ThemeModeCubit themeModeCubit;
  late MockGetOrSetInitialThemeModeUseCase mockGetOrSetInitialThemeModeUseCase;
  late MockSetThemeModeUseCase mockSetThemeModeUseCase;

  setUp(() {
    mockGetOrSetInitialThemeModeUseCase = MockGetOrSetInitialThemeModeUseCase();
    mockSetThemeModeUseCase = MockSetThemeModeUseCase();
    themeModeCubit = ThemeModeCubit(
      mockGetOrSetInitialThemeModeUseCase,
      mockSetThemeModeUseCase,
    );
  });

  tearDown(() {
    themeModeCubit.close();
  });

  test('initial state has system theme mode', () {
    expect(themeModeCubit.state.selectedThemeMode, equals(ThemeMode.system));
  });

  group('getCurrentTheme', () {
    blocTest<ThemeModeCubit, ThemeModeState>(
      'emits theme mode from use case',
      setUp: () {
        when(mockGetOrSetInitialThemeModeUseCase.execute(any))
            .thenReturn(ThemeMode.dark.index);
      },
      build: () => themeModeCubit,
      act: (cubit) => cubit.getCurrentTheme(),
      expect: () => [
        predicate<ThemeModeState>(
          (state) => state.selectedThemeMode == ThemeMode.dark,
        ),
      ],
      verify: (_) {
        verify(mockGetOrSetInitialThemeModeUseCase.execute(
          GetOrSetInitialThemeModeUseCaseParams(
            currentThemeModeId: ThemeMode.system.index,
          ),
        )).called(1);
      },
    );

    blocTest<ThemeModeCubit, ThemeModeState>(
      'handles errors gracefully',
      setUp: () {
        when(mockGetOrSetInitialThemeModeUseCase.execute(any))
            .thenThrow(Exception('Test error'));
      },
      build: () => themeModeCubit,
      act: (cubit) => cubit.getCurrentTheme(),
      expect: () => [], // Should not emit new states on error
    );
  });

  group('setTheme', () {
    blocTest<ThemeModeCubit, ThemeModeState>(
      'updates theme mode when valid index provided',
      build: () => themeModeCubit,
      act: (cubit) => cubit.setTheme(ThemeMode.dark.index),
      expect: () => [
        predicate<ThemeModeState>(
          (state) => state.selectedThemeMode == ThemeMode.dark,
        ),
      ],
      verify: (_) {
        verify(mockSetThemeModeUseCase.execute(
          SetThemeModeUseCaseParams(themeModeIndex: ThemeMode.dark.index),
        )).called(1);
      },
    );

    blocTest<ThemeModeCubit, ThemeModeState>(
      'does nothing when null index provided',
      build: () => themeModeCubit,
      act: (cubit) => cubit.setTheme(null),
      expect: () => [], // Should not emit any states
      verify: (_) {
        verifyNever(mockSetThemeModeUseCase.execute(any));
      },
    );

    blocTest<ThemeModeCubit, ThemeModeState>(
      'handles errors gracefully',
      setUp: () {
        when(mockSetThemeModeUseCase.execute(any))
            .thenThrow(Exception('Test error'));
      },
      build: () => themeModeCubit,
      act: (cubit) => cubit.setTheme(ThemeMode.dark.index),
      expect: () => [], // Should not emit new states on error
    );
  });
}