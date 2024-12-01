import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/core/widgets/form_wrapper.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_button.dart';
import 'package:amaravati_chamber/features/auth/presentation/widget/login_email_input.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FormWrapper(
      child: Align(
        alignment: const Alignment(0, -1 / 3),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: Spacing.s24),
              Text(
                "Welcome Back!",
                style: context.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s8),
              Text(
                "Please enter your email address to continue.",
                style: context.textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s48),
              const LoginEmailInput(),
              const SizedBox(height: Spacing.s24),
              const LoginButton(),
            ],
          ),
        ),
      ),
    );
  }
}