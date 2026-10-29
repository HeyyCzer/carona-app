import 'package:flutter/material.dart';

import '../theme.dart';

/// Campo de senha com botão de mostrar/ocultar.
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final TextInputAction action;
  final VoidCallback? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.action = TextInputAction.done,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      autofillHints: const [AutofillHints.password],
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        hintText: 'Senha',
        suffixIcon: IconButton(
          tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
