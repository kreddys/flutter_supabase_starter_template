import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/constants/spacings.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';
import 'package:amaravati_chamber/core/widgets/form_wrapper.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_address_button.dart';
import 'package:amaravati_chamber/features/user/presentation/widget/change_email_adress_email_input.dart';

class ChangeEmailAddressForm extends StatelessWidget {
  const ChangeEmailAddressForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FormWrapper(
      child: Center( // Added Center widget like in LoginForm
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/logo.png',
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
              Text(
                "Change email address",
                style: context.textTheme.headlineLarge,
                textAlign: TextAlign.center, // Added center alignment
              ),
              const SizedBox(height: Spacing.s16),
              const Text(
                "You will be required to confirm an email change to new email address.",
                softWrap: true,
                textAlign: TextAlign.center, // Added center alignment
              ),
              const SizedBox(height: Spacing.s16),
              const ChangeEmailAddressEmailInput(),
              const SizedBox(height: Spacing.s16),
              const ChangeEmailAddressButton(),
            ],
          ),
        ),
      ),
    );
  }
}
