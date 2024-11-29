import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'dependency_injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencyInjection() async {
  getIt.registerLazySingleton<http.Client>(() => http.Client());
  await getIt.init();
}