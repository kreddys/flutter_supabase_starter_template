import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/account_settings_section.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/help_settings_section.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/application_settings_section.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/info_settings_section.dart';
import 'package:amaravati_chamber/core/logging/app_logger.dart';
import 'package:amaravati_chamber/core/monitoring/sentry_monitoring.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building SettingsPage');
    SentryMonitoring.addBreadcrumb(
      message: 'Navigated to Settings page',
      category: 'navigation',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.s8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoSettingsSection(),
              SizedBox(height: Spacing.s16),
              HelpSettingsSection(),
              SizedBox(height: Spacing.s16),
              ApplicationSettingsSection(),
              SizedBox(height: Spacing.s16),
              AccountSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }
}