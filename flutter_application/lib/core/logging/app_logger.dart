import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Trace level logging
  static void trace(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.t(message);
  }

  // Debug level logging
  static void debug(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.d(message);
  }

  // Info level logging
  static void info(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.i(message);
  }

  // Warning level logging
  static void warning(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.w(message);
  }

  // Error level logging
  static void error(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message);
  }

  // What a Terrible Failure (WTF) level logging
  static void wtf(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.f(message);
  }
}