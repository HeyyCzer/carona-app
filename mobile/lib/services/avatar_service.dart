import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../api/carona_api.dart';
import 'auth_service.dart';

/// Foto de perfil do usuário logado: tira com a câmera (ou escolhe da galeria) e envia para o backend,
/// que guarda na pasta de avatares com o id do usuário como nome.
class AvatarService extends GetxService {
  final CaronaApi api;
  final AuthService auth;
  final ImagePicker _picker;

  final uploading = false.obs;

  AvatarService(this.api, this.auth, {ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Abre a câmera (frontal) ou a galeria; devolve false se o usuário desistiu.
  /// Lança [ApiException] se o envio falhar.
  Future<bool> pickAndUpload(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      // A foto aparece no máximo com uns 64 pt; 512 px sobra até em telas 3x e deixa o envio leve.
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (photo == null) return false;

    uploading.value = true;
    try {
      final bytes = await photo.readAsBytes();
      auth.updateUser(await api.uploadAvatar(bytes, filename: photo.name));
      return true;
    } finally {
      uploading.value = false;
    }
  }

  Future<void> remove() async {
    uploading.value = true;
    try {
      auth.updateUser(await api.deleteAvatar());
    } finally {
      uploading.value = false;
    }
  }
}
