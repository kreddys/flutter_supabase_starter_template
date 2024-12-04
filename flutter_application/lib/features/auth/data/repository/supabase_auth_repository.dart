import 'package:flutter/foundation.dart';
import 'package:amaravati_chamber/core/constants/urls.dart';
import 'package:amaravati_chamber/features/auth/data/mapper/auth_mapper.dart';
import 'package:amaravati_chamber/features/auth/domain/entity/auth_user_entity.dart';
import 'package:amaravati_chamber/features/auth/domain/exception/login_with_email_exception.dart';
import 'package:amaravati_chamber/features/auth/domain/repository/auth_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

@Injectable(as: AuthRepository)
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._supabaseAuth);

  final GoTrueClient _supabaseAuth;

  @override
  Future<void> loginWithEmail(String email) async {
    try {
      AppLogger.info('Attempting email login');
      SentryMonitoring.addBreadcrumb(
        message: 'Email login attempted',
        category: 'auth',
        data: {'email': email},
      );

      await _supabaseAuth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb ? null : Urls.loginCallbackUrl,
      );
      
      AppLogger.info('Login OTP sent successfully');
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Login failed: ${error.message}');
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'login_failure',
      );
      throw LoginWithEmailException(error.message);
    }
  }

  @override
  Future<void> logout() async {
    try {
      AppLogger.info('User logout initiated');
      SentryMonitoring.addBreadcrumb(
        message: 'User logout',
        category: 'auth',
      );
      
      await _supabaseAuth.signOut();
      
      AppLogger.info('User logged out successfully');
    } catch (error, stackTrace) {
      AppLogger.error('Logout failed: $error');
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'logout_failure',
      );
      rethrow;
    }
  }

  @override
  Stream<AuthState> getCurrentAuthState() {
    AppLogger.debug('Starting auth state stream');
    return _supabaseAuth.onAuthStateChange.map(
      (authState) => authState,
    );
  }

  @override
  AuthUserEntity? getLoggedInUser() {
    final user = _supabaseAuth.currentUser?.toUserEntity();
    AppLogger.debug('Retrieved logged in user: ${user?.id}');
    return user;
  }
}