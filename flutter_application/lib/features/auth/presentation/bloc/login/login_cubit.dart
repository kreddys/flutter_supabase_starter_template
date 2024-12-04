import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:amaravati_chamber/core/value_objects/email_value_object.dart';
import 'package:amaravati_chamber/features/auth/domain/exception/login_with_email_exception.dart';
import '../../../../../core/monitoring/sentry_monitoring.dart';
import 'package:amaravati_chamber/features/auth/domain/use_case/login_with_email_use_case.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';

part 'login_state.dart';

@injectable
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(
    this._loginWithEmailUseCase,
  ) : super(
          const LoginState(),
        );

  final LoginWithEmailUseCase _loginWithEmailUseCase;

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

    emit(
      state.copyWith(status: FormzSubmissionStatus.inProgress),
    );

    try {
      await _loginWithEmailUseCase.execute(
        LoginWithEmailParams(email: state.email.value),
      );

      emit(
        state.copyWith(status: FormzSubmissionStatus.success),
      );
    } on Exception catch (e, stackTrace) {

      await SentryMonitoring.captureException(
        e,
        stackTrace,
        tagValue: 'login_failure',
      );

      emit(state.copyWith(
        errorMessage: e is LoginWithEmailException ? e.message : null,
        status: FormzSubmissionStatus.failure,
      ));
    }
  }
}
