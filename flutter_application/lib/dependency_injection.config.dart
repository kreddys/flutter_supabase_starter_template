// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:amaravati_chamber/core/app/app_module.dart' as _i895;
import 'package:amaravati_chamber/core/voting/data/repositories/voting_repository.dart'
    as _i316;
import 'package:amaravati_chamber/core/voting/domain/repositories/i_voting_repository.dart'
    as _i567;
import 'package:amaravati_chamber/features/auth/data/repository/supabase_auth_repository.dart'
    as _i688;
import 'package:amaravati_chamber/features/auth/domain/repository/auth_repository.dart'
    as _i939;
import 'package:amaravati_chamber/features/auth/domain/use_case/get_current_auth_state_use_case.dart'
    as _i754;
import 'package:amaravati_chamber/features/auth/domain/use_case/get_logged_in_user_use_case.dart'
    as _i134;
import 'package:amaravati_chamber/features/auth/domain/use_case/login_with_email_use_case.dart'
    as _i900;
import 'package:amaravati_chamber/features/auth/domain/use_case/logout_use_case.dart'
    as _i804;
import 'package:amaravati_chamber/features/auth/presentation/bloc/auth_bloc.dart'
    as _i52;
import 'package:amaravati_chamber/features/auth/presentation/bloc/login/login_cubit.dart'
    as _i909;
import 'package:amaravati_chamber/features/home/presentation/bloc/bottom_navigation_bar/bottom_navigation_bar_cubit.dart'
    as _i813;
import 'package:amaravati_chamber/features/news/data/repositories/news_repository.dart'
    as _i1037;
import 'package:amaravati_chamber/features/news/domain/repositories/i_news_repository.dart'
    as _i179;
import 'package:amaravati_chamber/features/news/presentation/bloc/news_cubit.dart'
    as _i752;
import 'package:amaravati_chamber/features/theme_mode/data/repository/theme_mode_hive_repository.dart'
    as _i902;
import 'package:amaravati_chamber/features/theme_mode/domain/repository/theme_mode_repository.dart'
    as _i411;
import 'package:amaravati_chamber/features/theme_mode/domain/use_case/get_or_set_initial_theme_mode_use_case.dart'
    as _i257;
import 'package:amaravati_chamber/features/theme_mode/domain/use_case/set_theme_mode_id_use_case.dart'
    as _i736;
import 'package:amaravati_chamber/features/theme_mode/presentation/bloc/theme_mode_cubit.dart'
    as _i835;
import 'package:amaravati_chamber/features/user/data/repository/supabase_user_repository.dart'
    as _i93;
import 'package:amaravati_chamber/features/user/domain/repository/user_repository.dart'
    as _i194;
import 'package:amaravati_chamber/features/user/domain/use_case/change_email_address_use_case.dart'
    as _i1056;
import 'package:amaravati_chamber/features/user/presentation/bloc/change_email_address/change_email_address_cubit.dart'
    as _i552;
import 'package:get_it/get_it.dart' as _i174;
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
    gh.factory<_i813.BottomNavigationBarCubit>(
        () => _i813.BottomNavigationBarCubit());
    gh.factory<_i411.ThemeModeRepository>(
        () => _i902.ThemeModeHiveRepository());
    gh.factory<_i194.UserRepository>(() => _i93.SupabaseUserRepository(
          gh<_i590.GoTrueClient>(),
          gh<_i590.FunctionsClient>(),
        ));
    gh.factory<_i257.GetOrSetInitialThemeModeUseCase>(() =>
        _i257.GetOrSetInitialThemeModeUseCase(gh<_i411.ThemeModeRepository>()));
    gh.factory<_i736.SetThemeModeUseCase>(
        () => _i736.SetThemeModeUseCase(gh<_i411.ThemeModeRepository>()));
    gh.lazySingleton<_i179.INewsRepository>(
        () => _i1037.NewsRepository(gh<_i454.SupabaseClient>()));
    gh.factory<_i939.AuthRepository>(
        () => _i688.SupabaseAuthRepository(gh<_i454.GoTrueClient>()));
    gh.factory<_i1056.ChangeEmailAddressUseCase>(
        () => _i1056.ChangeEmailAddressUseCase(gh<_i194.UserRepository>()));
    gh.factory<_i835.ThemeModeCubit>(() => _i835.ThemeModeCubit(
          gh<_i257.GetOrSetInitialThemeModeUseCase>(),
          gh<_i736.SetThemeModeUseCase>(),
        ));
    gh.lazySingleton<_i567.IVotingRepository>(
        () => _i316.VotingRepository(gh<_i454.SupabaseClient>()));
    gh.factory<_i804.LogoutUseCase>(
        () => _i804.LogoutUseCase(gh<_i939.AuthRepository>()));
    gh.factory<_i134.GetLoggedInUserUseCase>(
        () => _i134.GetLoggedInUserUseCase(gh<_i939.AuthRepository>()));
    gh.factory<_i900.LoginWithEmailUseCase>(
        () => _i900.LoginWithEmailUseCase(gh<_i939.AuthRepository>()));
    gh.factory<_i754.GetCurrentAuthStateUseCase>(
        () => _i754.GetCurrentAuthStateUseCase(gh<_i939.AuthRepository>()));
    gh.factory<_i552.ChangeEmailAddressCubit>(
        () => _i552.ChangeEmailAddressCubit(
              gh<_i1056.ChangeEmailAddressUseCase>(),
              initialEmail: gh<String>(),
            ));
    gh.factory<_i752.NewsCubit>(() => _i752.NewsCubit(
          gh<_i179.INewsRepository>(),
          gh<_i567.IVotingRepository>(),
        ));
    gh.factory<_i52.AuthBloc>(() => _i52.AuthBloc(
          gh<_i134.GetLoggedInUserUseCase>(),
          gh<_i754.GetCurrentAuthStateUseCase>(),
          gh<_i804.LogoutUseCase>(),
        ));
    gh.factory<_i909.LoginCubit>(
        () => _i909.LoginCubit(gh<_i900.LoginWithEmailUseCase>()));
    return this;
  }
}

class _$AppModule extends _i895.AppModule {}
