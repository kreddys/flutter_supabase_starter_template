// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_application/core/app/app_module.dart' as _i690;
import 'package:flutter_application/features/auth/data/repository/supabase_auth_repository.dart'
    as _i476;
import 'package:flutter_application/features/auth/domain/repository/auth_repository.dart'
    as _i946;
import 'package:flutter_application/features/auth/domain/use_case/get_current_auth_state_use_case.dart'
    as _i781;
import 'package:flutter_application/features/auth/domain/use_case/get_logged_in_user_use_case.dart'
    as _i981;
import 'package:flutter_application/features/auth/domain/use_case/login_with_email_use_case.dart'
    as _i602;
import 'package:flutter_application/features/auth/domain/use_case/logout_use_case.dart'
    as _i603;
import 'package:flutter_application/features/auth/presentation/bloc/auth_bloc.dart'
    as _i964;
import 'package:flutter_application/features/auth/presentation/bloc/login/login_cubit.dart'
    as _i723;
import 'package:flutter_application/features/home/presentation/bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart'
    as _i740;
import 'package:flutter_application/features/news/data/repositories/news_repository.dart'
    as _i880;
import 'package:flutter_application/features/news/domain/repositories/i_news_repository.dart'
    as _i221;
import 'package:flutter_application/features/news/presentation/bloc/news_cubit.dart'
    as _i984;
import 'package:flutter_application/features/theme_mode/data/repository/theme_mode_hive_repository.dart'
    as _i279;
import 'package:flutter_application/features/theme_mode/domain/repository/theme_mode_repository.dart'
    as _i12;
import 'package:flutter_application/features/theme_mode/domain/use_case/get_or_set_initial_theme_mode_use_case.dart'
    as _i1023;
import 'package:flutter_application/features/theme_mode/domain/use_case/set_theme_mode_id_use_case.dart'
    as _i727;
import 'package:flutter_application/features/theme_mode/presentation/bloc/theme_mode_cubit.dart'
    as _i621;
import 'package:flutter_application/features/user/data/repository/supabase_user_repository.dart'
    as _i763;
import 'package:flutter_application/features/user/domain/repository/user_repository.dart'
    as _i392;
import 'package:flutter_application/features/user/domain/use_case/change_email_address_use_case.dart'
    as _i627;
import 'package:flutter_application/features/user/presentation/bloc/change_email_address/change_email_address_cubit.dart'
    as _i75;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase/supabase.dart' as _i590;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final appModule = _$AppModule();
    gh.factory<_i454.SupabaseClient>(() => appModule.supabaseClient);
    gh.factory<_i454.GoTrueClient>(() => appModule.supabaseAuth);
    gh.factory<_i454.FunctionsClient>(() => appModule.functionsClient);
    gh.factory<_i740.BottomNavigationBarCubit>(
        () => _i740.BottomNavigationBarCubit());
    gh.lazySingleton<_i221.INewsRepository>(
        () => _i880.NewsRepository(gh<_i519.Client>()));
    gh.factory<_i12.ThemeModeRepository>(() => _i279.ThemeModeHiveRepository());
    gh.factory<_i1023.GetOrSetInitialThemeModeUseCase>(() =>
        _i1023.GetOrSetInitialThemeModeUseCase(gh<_i12.ThemeModeRepository>()));
    gh.factory<_i727.SetThemeModeUseCase>(
        () => _i727.SetThemeModeUseCase(gh<_i12.ThemeModeRepository>()));
    gh.factory<_i984.NewsCubit>(
        () => _i984.NewsCubit(gh<_i221.INewsRepository>()));
    gh.factory<_i392.UserRepository>(() => _i763.SupabaseUserRepository(
          gh<_i590.GoTrueClient>(),
          gh<_i590.FunctionsClient>(),
        ));
    gh.factory<_i621.ThemeModeCubit>(() => _i621.ThemeModeCubit(
          gh<_i1023.GetOrSetInitialThemeModeUseCase>(),
          gh<_i727.SetThemeModeUseCase>(),
        ));
    gh.factory<_i946.AuthRepository>(
        () => _i476.SupabaseAuthRepository(gh<_i454.GoTrueClient>()));
    gh.factory<_i627.ChangeEmailAddressUseCase>(
        () => _i627.ChangeEmailAddressUseCase(gh<_i392.UserRepository>()));
    gh.factory<_i603.LogoutUseCase>(
        () => _i603.LogoutUseCase(gh<_i946.AuthRepository>()));
    gh.factory<_i981.GetLoggedInUserUseCase>(
        () => _i981.GetLoggedInUserUseCase(gh<_i946.AuthRepository>()));
    gh.factory<_i602.LoginWithEmailUseCase>(
        () => _i602.LoginWithEmailUseCase(gh<_i946.AuthRepository>()));
    gh.factory<_i781.GetCurrentAuthStateUseCase>(
        () => _i781.GetCurrentAuthStateUseCase(gh<_i946.AuthRepository>()));
    gh.factory<_i723.LoginCubit>(
        () => _i723.LoginCubit(gh<_i602.LoginWithEmailUseCase>()));
    gh.factory<_i75.ChangeEmailAddressCubit>(() =>
        _i75.ChangeEmailAddressCubit(gh<_i627.ChangeEmailAddressUseCase>()));
    gh.factory<_i964.AuthBloc>(() => _i964.AuthBloc(
          gh<_i981.GetLoggedInUserUseCase>(),
          gh<_i781.GetCurrentAuthStateUseCase>(),
          gh<_i603.LogoutUseCase>(),
        ));
    return this;
  }
}

class _$AppModule extends _i690.AppModule {}
