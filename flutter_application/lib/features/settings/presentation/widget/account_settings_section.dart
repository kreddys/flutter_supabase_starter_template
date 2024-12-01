import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_section.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_tile.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_address_settings_tile.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/logout_settings_tile.dart';
import 'package:amaravati_chamber/features/user/presentation/bloc/change_email_address/change_email_address_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import

class AccountSettingsSection extends StatelessWidget {
  const AccountSettingsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    
    return BlocProvider(
      create: (context) => GetIt.I<ChangeEmailAddressCubit>()..emailChanged(currentEmail),
      child: SettingsSection(
        title: 'Account',
        items: [
          BlocBuilder<ChangeEmailAddressCubit, ChangeEmailAddressState>(
            builder: (context, state) {
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