// account_settings_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_section.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_tile.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_address_settings_tile.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/logout_settings_tile.dart';
import 'package:amaravati_chamber/features/user/presentation/bloc/change_email_address/change_email_address_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amaravati_chamber/core/logging/app_logger.dart';
import 'package:amaravati_chamber/core/monitoring/sentry_monitoring.dart';

class AccountSettingsSection extends StatelessWidget {
  const AccountSettingsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building AccountSettingsSection');
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    
    AppLogger.info('Current user email: $currentEmail');
    SentryMonitoring.addBreadcrumb(
      message: 'Loading account settings for user',
      category: 'user_info',
    );
    
    return BlocProvider(
      create: (context) {
        AppLogger.debug('Creating ChangeEmailAddressCubit');
        return GetIt.I<ChangeEmailAddressCubit>()..emailChanged(currentEmail);
      },
      child: SettingsSection(
        title: 'Account',
        items: [
          BlocBuilder<ChangeEmailAddressCubit, ChangeEmailAddressState>(
            builder: (context, state) {
              AppLogger.debug('Building email display tile with state: ${state.email.value}');
              return SettingsTile(
                leading: Icons.email,
                title: 'Email',
                subtitle: state.email.value,
                onTap: null,
              );
            },
          ),
          const ChangeEmailAddressSettingsTile(),
          const LogoutSettingsTile(),
        ],
      ),
    );
  }
}