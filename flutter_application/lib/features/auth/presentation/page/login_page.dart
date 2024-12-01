import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';

import 'package:amaravati_chamber/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amaravati_chamber/features/auth/presentation/bloc/login/login_cubit.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_form.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/core/router/routes.dart';
import 'package:amaravati_chamber/dependency_injection.dart';

import '../../../../core/constants/spacings.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthBlocListener(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: BlocProvider(
                create: (context) => getIt<LoginCubit>(),
                child: BlocListener<LoginCubit, LoginState>(
                  listener: (context, state) {
                    switch (state.status) {
                      case FormzSubmissionStatus.failure:
                        context.showErrorSnackBarMessage(
                          state.errorMessage ?? 'Failed to sign in. Please try again.',
                        );
                        return;
                      case FormzSubmissionStatus.success:
                        context.showSnackBarMessage("Email with login link has been sent.");
                        return;
                      default:
                        return;
                    }
                  },
                  child: const LoginForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBlocListener extends StatelessWidget {
  const _AuthBlocListener({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUserAuthenticated) {
          context.go(Routes.home.path);
        }
      },
      child: child,
    );
  }
}
