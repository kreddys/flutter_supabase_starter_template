import 'package:flutter/material.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_tile.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_section.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:amaravati_chamber/core/logging/app_logger.dart';
import 'package:amaravati_chamber/core/monitoring/sentry_monitoring.dart';

class InfoSettingsSection extends StatefulWidget {
  const InfoSettingsSection({
    super.key,
  });

  @override
  State<InfoSettingsSection> createState() => _InfoSettingsSectionState();
}

class _InfoSettingsSectionState extends State<InfoSettingsSection> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      AppLogger.debug('Initializing package info');
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = info;
      });
      AppLogger.info('Package info initialized: version ${info.version}');
      SentryMonitoring.addBreadcrumb(
        message: 'Package info loaded: ${info.version}',
        category: 'info',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize package info', error: e, stackTrace: stackTrace);
      SentryMonitoring.captureException(e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building InfoSettingsSection');
    return SettingsSection(
      title: 'Info',
      items: [
        SettingsTile(
          leading: Icons.info_outline,
          title: "Version: ${_packageInfo.version}",
          onTap: null,
        ),
      ],
    );
  }
}