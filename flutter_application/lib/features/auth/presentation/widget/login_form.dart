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
      child: Center( // Center the content vertically
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/logo.png', // Make sure to add your logo to assets
                height: 100,
                width: 100,
              ),
              const SizedBox(height: Spacing.s24),
              Text(
                "Amaravati Chamber",
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s32),
              const LoginEmailInput(),
              const SizedBox(height: Spacing.s16),
              const LoginButton(),
            ],
          ),
        ),
      ),
    );
  }
}