import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ui/ui.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Dados\nPessoais.',
      subtitle: 'Insira seus dados abaixo para criar\nsua conta.',
      footerText: 'Já possui uma conta?',
      footerAction: 'Faça Login',
      onFooterTap: Get.back,
      children: [
        AutofillGroup(
          child: Column(
            children: [
              TextField(
                controller: controller.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(hintText: 'Nome Completo'),
              ),
              const SizedBox(height: 20),
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
              label: 'Próximo',
              loading: controller.loading.value,
              onPressed: controller.canSubmit.value ? controller.submit : null,
            )),
      ],
    );
  }
}
