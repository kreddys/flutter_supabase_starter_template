import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryMonitoring {
  static Future<void> initialize({
    required String dsn,
    required Future<void> Function() appRunner,
  }) async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 1.0;
        options.enableAutoSessionTracking = true;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
        options.debug = kDebugMode;
      },
      appRunner: appRunner,
    );
  }

  static Future<void> captureException(
    dynamic exception,
    dynamic stackTrace, {
    String? tagValue,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (tagValue != null) {
          scope.setTag('custom_tag', tagValue);
        }
      },
    );
  }

  static Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
      ),
    );
  }

  static ISentrySpan startTransaction(String name, String operation) {
    return Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );
  }
}