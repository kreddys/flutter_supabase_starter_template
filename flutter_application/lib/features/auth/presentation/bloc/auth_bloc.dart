import 'dart:async';
import '../../../../core/monitoring/sentry_monitoring.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:amaravati_chamber/core/use_cases/no_params.dart';
import 'package:amaravati_chamber/features/auth/data/mapper/auth_mapper.dart';
import 'package:amaravati_chamber/features/auth/domain/entity/auth_user_entity.dart';
import 'package:amaravati_chamber/features/auth/domain/use_case/get_current_auth_state_use_case.dart';
import 'package:amaravati_chamber/features/auth/domain/use_case/logout_use_case.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth;

import '../../domain/use_case/get_logged_in_user_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._getLoggedInUserUseCase,
    this._getAuthStateUseCase,
    this._logoutUseCase,
  ) : super(
          const AuthInitial(),
        ) {
    on<AuthInitialCheckRequested>(_onInitialAuthChecked);
    on<AuthOnCurrentUserChanged>(_onCurrentUserChanged);
    on<AuthLogoutButtonPressed>(_onLogoutButtonPressed);

    _startUserSubscription();
  }

  final GetLoggedInUserUseCase _getLoggedInUserUseCase;
  final GetCurrentAuthStateUseCase _getAuthStateUseCase;
  final LogoutUseCase _logoutUseCase;

  late final StreamSubscription<supabase_auth.AuthState>? _authSubscription;

  void _startUserSubscription() {
    _authSubscription = _getAuthStateUseCase.execute(NoParams()).listen(
          (supabaseAuthState) => add(AuthOnCurrentUserChanged(
            supabaseAuthState.session?.user.toUserEntity(),
          )),
        );
  }

Future<void> _onInitialAuthChecked(
  AuthInitialCheckRequested event,
  Emitter<AuthState> emit,
) async {
  try {
    AuthUserEntity? signedInUser = _getLoggedInUserUseCase.execute(NoParams());
    
    // Add breadcrumb for auth state check
    await SentryMonitoring.addBreadcrumb(
      message: 'Initial auth state checked',
      category: 'auth',
      data: {'isAuthenticated': signedInUser != null},
    );

    signedInUser != null
        ? emit(AuthUserAuthenticated(signedInUser))
        : emit(const AuthUserUnauthenticated());
  } catch (error, stackTrace) {
    await SentryMonitoring.captureException(
      error,
      stackTrace,
      tagValue: 'auth_check_failure',
    );
    emit(const AuthUserUnauthenticated());
  }
}

  Future<void> _onCurrentUserChanged(
    AuthOnCurrentUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    event.user != null
        ? emit(AuthUserAuthenticated(event.user!))
        : emit(const AuthUserUnauthenticated());
  }

Future<void> _onLogoutButtonPressed(
  AuthLogoutButtonPressed event,
  Emitter<AuthState> emit,
) async {
  try {
    await _logoutUseCase.execute(NoParams());
    
    // Add breadcrumb for logout
    await SentryMonitoring.addBreadcrumb(
      message: 'User logged out',
      category: 'auth',
    );
  } catch (error, stackTrace) {
    await SentryMonitoring.captureException(
      error,
      stackTrace,
      tagValue: 'logout_failure',
    );
  }
}

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
