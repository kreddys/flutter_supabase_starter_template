import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/urls.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_tile.dart';
import 'package:amaravati_chamber/features/settings/presentation/widget/settings_section.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:amaravati_chamber/core/logging/app_logger.dart';
import 'package:amaravati_chamber/core/monitoring/sentry_monitoring.dart';

class HelpSettingsSection extends StatelessWidget {
  const HelpSettingsSection({
    super.key,
  });

  Future<void> _handleEmailTap() async {
    AppLogger.info('User tapped contact email link');
    SentryMonitoring.addBreadcrumb(
      message: 'User initiated email contact',
      category: 'user_action',
    );
    await launchUrl(Uri.parse("mailto:${Urls.contactEmail}"));
  }

  Future<void> _handleTermsOfServiceTap() async {
    AppLogger.info('User tapped Terms of Service link');
    SentryMonitoring.addBreadcrumb(
      message: 'User viewed Terms of Service',
      category: 'user_action',
    );
    await launchUrl(Uri.parse(Urls.termsService));
  }

  Future<void> _handlePrivacyPolicyTap() async {
    AppLogger.info('User tapped Privacy Policy link');
    SentryMonitoring.addBreadcrumb(
      message: 'User viewed Privacy Policy',
      category: 'user_action',
    );
    await launchUrl(Uri.parse(Urls.privacyPolicy));
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building HelpSettingsSection');
    return SettingsSection(
      title: "Help",
      items: [
        SettingsTile(
          leading: Icons.forward_to_inbox,
          title: "Email",
          subtitle: "Tap here to contact over email.",
          onTap: _handleEmailTap,
        ),
        SettingsTile(
          leading: Icons.description_outlined,
          title: "Terms of Service",
          onTap: _handleTermsOfServiceTap,
        ),
        SettingsTile(
          leading: Icons.privacy_tip_outlined,
          title: "Privacy Policy",
          onTap: _handlePrivacyPolicyTap,
        ),
      ],
    );
  }
}