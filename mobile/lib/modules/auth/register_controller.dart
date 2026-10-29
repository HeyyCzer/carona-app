import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../ui/ui.dart';

class RegisterController extends GetxController {
  final AuthService _auth = Get.find();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  final loading = false.obs;
  final canSubmit = false.obs;
  final obscure = true.obs;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void onInit() {
    super.onInit();
    for (final c in [name, email, password]) {
      c.addListener(() => canSubmit.value = validationError == null);
    }
  }

  /// Mesmas regras do UserRegisterDto do backend.
  String? get validationError {
    final n = name.text.trim();
    if (n.length < 2 || n.length > 50) return 'Informe seu nome (2 a 50 caracteres).';
    if (!_emailPattern.hasMatch(email.text.trim())) return 'Informe um e-mail válido.';
    if (password.text.length < 8 || password.text.length > 72) return 'A senha precisa ter pelo menos 8 caracteres.';
    return null;
  }

  Future<void> submit() async {
    final error = validationError;
    if (error != null) {
      showMessage(error, error: true);
      return;
    }
    if (loading.value) return;
    loading.value = true;
    try {
      await _auth.register(name.text, email.text, password.text);
      Get.offAllNamed(Routes.home);
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
