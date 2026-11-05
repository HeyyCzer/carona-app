import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/avatar_service.dart';
import '../../theme.dart';
import '../../ui/ui.dart';

/// Folha inferior com os dados da conta, a foto de perfil e o botão de sair.
void showProfileSheet() {
  final auth = Get.find<AuthService>();
  final avatars = Get.find<AvatarService>();
  if (auth.user.value == null) return;

  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Obx(() {
          final user = auth.user.value;
          if (user == null) return const SizedBox.shrink();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: avatars.uploading.value ? null : () => _showPhotoOptions(hasPhoto: user.avatarUrl != null),
                child: Stack(
                  children: [
                    Avatar(name: user.name, url: user.avatarUrl, size: 88),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: avatars.uploading.value
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.photo_camera_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
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
          );
        }),
      ),
    ),
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  );
}

void _showPhotoOptions({required bool hasPhoto}) {
  final avatars = Get.find<AvatarService>();

  /// [action] devolve false quando o usuário desiste (fecha a câmera sem tirar foto).
  Future<void> run(Future<bool> Function() action, String success) async {
    Get.back();
    try {
      if (await action()) showMessage(success);
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    }
  }

  Future<void> pick(ImageSource source) => run(() => avatars.pickAndUpload(source), 'Foto atualizada.');

  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => pick(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => pick(ImageSource.gallery),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text('Remover foto', style: TextStyle(color: AppColors.danger)),
                onTap: () => run(() async {
                  await avatars.remove();
                  return true;
                }, 'Foto removida.'),
              ),
          ],
        ),
      ),
    ),
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  );
}
