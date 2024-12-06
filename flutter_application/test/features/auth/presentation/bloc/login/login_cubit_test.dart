// login_cubit_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:formz/formz.dart';
import 'package:amaravati_chamber/features/auth/domain/use_case/login_with_email_use_case.dart';
import 'package:amaravati_chamber/features/auth/presentation/bloc/login/login_cubit.dart';
import 'package:amaravati_chamber/features/auth/domain/exception/login_with_email_exception.dart';
import 'package:amaravati_chamber/core/value_objects/email_value_object.dart';

@GenerateMocks([LoginWithEmailUseCase])
import 'login_cubit_test.mocks.dart';

void main() {
  late LoginCubit loginCubit;
  late MockLoginWithEmailUseCase mockLoginWithEmailUseCase;

  setUp(() {
    mockLoginWithEmailUseCase = MockLoginWithEmailUseCase();
    loginCubit = LoginCubit(mockLoginWithEmailUseCase);
  });

  tearDown(() {
    loginCubit.close();
  });

  group('LoginCubit', () {
    test('initial state is correct', () {
      expect(loginCubit.state, const LoginState());
      expect(loginCubit.state.status, FormzSubmissionStatus.initial);
      expect(loginCubit.state.isValid, false);
      expect(loginCubit.state.errorMessage, null);
    });

    group('emailChanged', () {
      test('emits invalid state for invalid email', () {
        // act
        loginCubit.emailChanged('invalid-email');

        // assert
        expect(loginCubit.state.email.error, EmailValidationError.invalid);
        expect(loginCubit.state.isValid, false);
      });

      test('emits valid state for valid email', () {
        // act
        loginCubit.emailChanged('test@example.com');

        // assert
        expect(loginCubit.state.email.error, null);
        expect(loginCubit.state.isValid, true);
      });

      test('emits updated state for empty email', () {
        // act
        loginCubit.emailChanged('');

        // assert
        expect(loginCubit.state.email.value, '');
        expect(loginCubit.state.isValid, false);
      });
    });

    group('submitForm', () {
      test('does nothing when form is invalid', () async {
        // arrange
        loginCubit.emailChanged('invalid-email');

        // act
        loginCubit.submitForm();

        // assert
        verifyNever(mockLoginWithEmailUseCase.execute(any));
        expect(loginCubit.state.status, FormzSubmissionStatus.initial);
      });

test('submits form when valid and emits success', () async {
  // arrange
  const validEmail = 'test@example.com';
  loginCubit.emailChanged(validEmail);

  when(mockLoginWithEmailUseCase.execute(any))
      .thenAnswer((_) async => null);

  // act & assert
  expectLater(
    loginCubit.stream,
    emitsInOrder([
      predicate<LoginState>(
        (state) => state.status == FormzSubmissionStatus.inProgress,
      ),
      predicate<LoginState>(
        (state) => state.status == FormzSubmissionStatus.success,
      ),
    ]),
  );

  loginCubit.submitForm();

  // Wait for the async operation to complete
  await Future<void>.delayed(Duration.zero);

  // Verify the use case was called
  verify(mockLoginWithEmailUseCase
      .execute(LoginWithEmailParams(email: validEmail)))
      .called(1);
});

test('handles LoginWithEmailException correctly', () async {
  // arrange
  const validEmail = 'test@example.com';
  const errorMessage = 'Login failed';
  loginCubit.emailChanged(validEmail);

  when(mockLoginWithEmailUseCase.execute(any))
      .thenThrow(const LoginWithEmailException(errorMessage));

  // act & assert
  expectLater(
    loginCubit.stream,
    emitsInOrder([
      predicate<LoginState>(
        (state) => state.status == FormzSubmissionStatus.inProgress,
      ),
      predicate<LoginState>(
        (state) => state.status == FormzSubmissionStatus.failure &&
                   state.errorMessage == errorMessage,
      ),
    ]),
  );

  loginCubit.submitForm();

  // Wait for the async operation to complete
  await Future<void>.delayed(Duration.zero);

  // Verify the use case was called
  verify(mockLoginWithEmailUseCase
      .execute(LoginWithEmailParams(email: validEmail)))
      .called(1);
});

test('handles generic exception correctly', () async {
  // arrange
  const validEmail = 'test@example.com';
  loginCubit.emailChanged(validEmail);

  when(mockLoginWithEmailUseCase.execute(any))
      .thenThrow(Exception('Generic error'));

  // act & assert
  expectLater(
    loginCubit.stream,
    emitsInOrder([
      predicate<LoginState>(
        (state) => state.status == FormzSubmissionStatus.inProgress,
      ),
      predicate<LoginState>(
        (state) => state.status == FormzSubmissionStatus.failure &&
                   state.errorMessage == null, // Generic exceptions don't set error message
      ),
    ]),
  );

  loginCubit.submitForm();

  // Wait for the async operation to complete
  await Future<void>.delayed(Duration.zero);

  // Verify the use case was called
  verify(mockLoginWithEmailUseCase
      .execute(LoginWithEmailParams(email: validEmail)))
      .called(1);
});

      test('emits correct states for successful submission', () async {
        // arrange
        const validEmail = 'test@example.com';
        loginCubit.emailChanged(validEmail);

        when(mockLoginWithEmailUseCase.execute(any))
            .thenAnswer((_) async => null);

        // act & assert
        expect(
          loginCubit.stream,
          emitsInOrder([
            predicate<LoginState>(
              (state) => state.status == FormzSubmissionStatus.inProgress,
            ),
            predicate<LoginState>(
              (state) => state.status == FormzSubmissionStatus.success,
            ),
          ]),
        );

        loginCubit.submitForm();
      });
    });
  });
}