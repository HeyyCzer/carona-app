import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../ui/ui.dart';

/// Folha inferior com os dados da conta e o botão de sair.
void showProfileSheet() {
  final auth = Get.find<AuthService>();
  final user = auth.user.value;
  if (user == null) return;

  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(name: user.name, size: 64),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(user.email, style: mutedStyle),
            const SizedBox(height: 24),
            SoftButton(
              label: 'Sair da conta',
              icon: Icons.logout_rounded,
              foreground: AppColors.danger,
              onPressed: () async {
                Get.back();
                if (await confirm('Sair da conta?', 'Você precisará entrar de novo com e-mail e senha.',
                    confirmLabel: 'Sair', destructive: true)) {
                  auth.logout();
                }
              },
            ),
          ],
        ),
      ),
    ),
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  );
}
