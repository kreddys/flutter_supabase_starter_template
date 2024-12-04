import 'package:amaravati_chamber/core/use_cases/use_case.dart';
import 'package:amaravati_chamber/features/user/domain/repository/user_repository.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';
import 'package:sentry/sentry.dart';
import 'package:amaravati_chamber/features/user/domain/exception/change_email_address_exception.dart'; 

@injectable
class ChangeEmailAddressUseCase extends UseCase<void, ChangeEmailAddressUseCaseParams> {
  ChangeEmailAddressUseCase(
    this._userRepository,
  );

  final UserRepository _userRepository;

  @override
  Future<void> execute(ChangeEmailAddressUseCaseParams params) async {
    final transaction = SentryMonitoring.startTransaction(
      'change_email_address',
      'email_operation',
    );

    try {
      await _userRepository.changeEmailAddress(params.email);
      transaction.finish(status: const SpanStatus.ok());
    } catch (error, stackTrace) {
      transaction.finish(status: const SpanStatus.internalError());
      await SentryMonitoring.captureException(
        error,
        stackTrace,
        tagValue: 'change_email_failure',
      );
      throw ChangeEmailAddressException(message: error.toString());
    }
  }
}

class ChangeEmailAddressUseCaseParams {
  ChangeEmailAddressUseCaseParams({
    required this.email,
  });

  final String email;
}