import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Sua carona\npara o futuro.',
      subtitle: 'Bem-vindo de volta! Faça login\npara continuar.',
      footerText: 'Ainda não possui conta?',
      footerAction: 'Cadastre-se',
      onFooterTap: () => Get.toNamed(Routes.register),
      children: [
        AutofillGroup(
          child: Column(
            children: [
              TextField(
                controller: controller.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(hintText: 'E-mail'),
              ),
              const SizedBox(height: 20),
              Obx(() => PasswordField(
                    controller: controller.password,
                    obscure: controller.obscure.value,
                    onToggle: controller.obscure.toggle,
                    onSubmitted: controller.submit,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Obx(() => PrimaryButton(
              label: 'Login',
              loading: controller.loading.value,
              onPressed: controller.canSubmit.value ? controller.submit : null,
            )),
        const SizedBox(height: 12),
        TextButton(
          onPressed: controller.forgotPassword,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.primary),
          child: const Text('Esqueci minha senha', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
