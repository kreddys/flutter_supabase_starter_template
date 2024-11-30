import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'dependency_injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencyInjection() async {
  // No need to register SupabaseClient here since it's already handled in AppModule
  await getIt.init();
}