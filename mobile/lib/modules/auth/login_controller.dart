import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../ui/ui.dart';

class LoginController extends GetxController {
  final AuthService _auth = Get.find();

  final email = TextEditingController();
  final password = TextEditingController();

  final loading = false.obs;
  final canSubmit = false.obs;
  final obscure = true.obs;

  @override
  void onInit() {
    super.onInit();
    void validate() => canSubmit.value = email.text.trim().isNotEmpty && password.text.isNotEmpty;
    email.addListener(validate);
    password.addListener(validate);
  }

  Future<void> submit() async {
    if (!canSubmit.value || loading.value) return;
    loading.value = true;
    try {
      await _auth.login(email.text, password.text);
      Get.offAllNamed(Routes.home);
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      loading.value = false;
    }
  }

  void forgotPassword() =>
      showMessage('A recuperação de senha ainda não está disponível. Procure a secretaria do curso.');

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
