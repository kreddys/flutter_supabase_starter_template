import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/extensions/hive_extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amaravati_chamber/core/app/app.dart';
import 'package:amaravati_chamber/dependency_injection.dart';
import 'package:amaravati_chamber/core/monitoring/sentry_monitoring.dart';
void main() async {
  await SentryMonitoring.initialize(
    dsn: 'https://c29f6c71f35d4fddce84079d1fd11f5e@o4508407207690240.ingest.us.sentry.io/4508407209000961∂¬',
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      await _initializeSupabase();
      await _initializeHive();
      await configureDependencyInjection();

      runApp(
        const FlutterSupabaseStarterApp(),
      );
    },
  );
}

Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: "https://kmisqlvoiofymxicxiwv.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttaXNxbHZvaW9meW14aWN4aXd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI4MTU3NjQsImV4cCI6MjA0ODM5MTc2NH0.BqbDLNjAeRA_4g7apBTsikG4QUMWGIFUokiA3spiptk",
  );
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  await Hive.openThemeModeBox();
}