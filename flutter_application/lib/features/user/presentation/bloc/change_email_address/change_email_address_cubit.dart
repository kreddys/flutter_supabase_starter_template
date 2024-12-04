import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:amaravati_chamber/core/value_objects/email_value_object.dart';
import 'package:amaravati_chamber/features/user/domain/exception/change_email_address_exception.dart';
import 'package:amaravati_chamber/features/user/domain/use_case/change_email_address_use_case.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import '../../../../../core/monitoring/sentry_monitoring.dart';

part '../change_email_address/change_email_address_state.dart';

@injectable
class ChangeEmailAddressCubit extends Cubit<ChangeEmailAddressState> {
  final ChangeEmailAddressUseCase _changeEmailAddressUseCase;

  @factoryMethod
  ChangeEmailAddressCubit(
    this._changeEmailAddressUseCase,
  ) : super(ChangeEmailAddressState(
          email: EmailValueObject.dirty(''),
        ));

  void emailChanged(String value) {
    final email = EmailValueObject.dirty(value);

    emit(state.copyWith(
      email: email,
      isValid: Formz.validate([
        email,
      ]),
    ));
  }

  void submitForm() async {
    if (!state.isValid) return;

    emit(state.copyWith(
      status: FormzSubmissionStatus.inProgress,
    ));

    try {
      await _changeEmailAddressUseCase.execute(
        ChangeEmailAddressUseCaseParams(email: state.email.value),
      );

      emit(state.copyWith(
        status: FormzSubmissionStatus.success,
        email: const EmailValueObject.pure(),
      ));
    } on Exception catch (ex, stackTrace) {

      await SentryMonitoring.captureException(
        ex,
        stackTrace,
        tagValue: 'change_email_failure',
    );

      emit(state.copyWith(
        errorMessage: ex is ChangeEmailAddressException ? ex.message : null,
        status: FormzSubmissionStatus.failure,
      ));
    }
  }
}
