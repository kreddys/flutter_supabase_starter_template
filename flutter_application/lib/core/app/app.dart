import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/core/router/router.dart';
import 'package:amaravati_chamber/core/app/app_theme.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import 'package:amaravati_chamber/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amaravati_chamber/features/theme_mode/presentation/bloc/theme_mode_cubit.dart';
import 'package:amaravati_chamber/core/app/app_theme.dart' show theme, darkTheme;

class FlutterSupabaseStarterApp extends StatelessWidget {
  const FlutterSupabaseStarterApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _AppBlocProvider(
      child: BlocBuilder<ThemeModeCubit, ThemeModeState>(
        buildWhen: (previous, current) => previous.selectedThemeMode != current.selectedThemeMode,
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Amaravati Chamber',
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: state.selectedThemeMode,
          );
        },
      ),
    );
  }
}

class _AppBlocProvider extends StatelessWidget {
  const _AppBlocProvider({
    super.key,
    required this.child,
  });

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => getIt<AuthBloc>()
              ..add(
                const AuthInitialCheckRequested(),
              )),
        BlocProvider(
          create: (_) => getIt<ThemeModeCubit>()..getCurrentTheme(),
        ),
      ],
      child: child,
    );
  }
}
