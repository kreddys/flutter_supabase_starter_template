// application_settings_section.dart
import 'package:flutter/material.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_section.dart';
import 'package:amaravati_chamber/features/theme_mode/presentation/widget/theme_mode_settings_tile.dart';
import 'package:amaravati_chamber/core/logging/app_logger.dart';
import 'package:amaravati_chamber/core/monitoring/sentry_monitoring.dart';

class ApplicationSettingsSection extends StatelessWidget {
  const ApplicationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building ApplicationSettingsSection');
    SentryMonitoring.addBreadcrumb(
      message: 'Loading application settings',
      category: 'settings',
    );

    return const SettingsSection(
      title: "Application",
      items: [
        ThemeModeSettingsTile(),
      ],
    );
  }
}