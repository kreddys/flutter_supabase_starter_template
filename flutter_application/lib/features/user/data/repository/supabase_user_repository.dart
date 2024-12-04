import 'package:flutter/foundation.dart';
import 'package:amaravati_chamber/core/constants/urls.dart';
import 'package:amaravati_chamber/features/user/domain/exception/change_email_address_exception.dart';
import 'package:amaravati_chamber/features/user/domain/repository/user_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

@Injectable(as: UserRepository)
class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(
    this._supabaseAuth,
    this._functionsClient,
  );

  final GoTrueClient _supabaseAuth;
  final FunctionsClient _functionsClient;

  @override
  Future<void> changeEmailAddress(String newEmailAddress) async {
    try {
      AppLogger.info('Attempting to change email address');
      SentryMonitoring.addBreadcrumb(
        message: 'Email address change attempted',
        category: 'user',
        data: {'new_email': newEmailAddress},
      );

      await _supabaseAuth.updateUser(
        UserAttributes(email: newEmailAddress),
        emailRedirectTo: kIsWeb ? null : Urls.changeEmailCallbackUrl,
      );
      
      AppLogger.info('Email change request sent successfully');
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('Failed to change email: ${error.message}');
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'email_change_failure',
      );
      throw (ChangeEmailAddressException(message: error.message));
    }
  }
}