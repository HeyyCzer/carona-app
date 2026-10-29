import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme.dart';

/// Feedback rápido no rodapé da tela.
void showMessage(String text, {bool error = false}) {
  Get.closeCurrentSnackbar();
  Get.showSnackbar(GetSnackBar(
    message: text,
    duration: const Duration(seconds: 3),
    backgroundColor: error ? AppColors.danger : AppColors.text,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
    snackPosition: SnackPosition.BOTTOM,
  ));
}

/// Diálogo de confirmação; devolve true se o usuário confirmar.
Future<bool> confirm(
  String title,
  String message, {
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Voltar')),
        TextButton(
          onPressed: () => Get.back(result: true),
          style: TextButton.styleFrom(foregroundColor: destructive ? AppColors.danger : AppColors.primary),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
