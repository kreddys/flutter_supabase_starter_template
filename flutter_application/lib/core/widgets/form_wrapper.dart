import 'package:flutter/material.dart';
import 'package:amaravati_chamber/core/extensions/build_context_extensions.dart';

class FormWrapper extends StatelessWidget {
  const FormWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.closeKeyboard(),
      child: Form(
        child: child,
      ),
    );
  }
}
