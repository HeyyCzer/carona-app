import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../services/auth_service.dart';
import '../../services/messages_service.dart';
import '../../ui/ui.dart';

/// Respostas rápidas mostradas acima do campo, como no Uber.
const chatPresets = [
  'Estou a caminho',
  'Cheguei no ponto de embarque',
  'Chego em 5 minutos',
  'Vou me atrasar um pouco',
  'Onde você está?',
  'Já estou te esperando',
  'Ok, combinado!',
  'Obrigado!',
];

class ChatController extends GetxController {
  final Person person;
  final MessagesService _messages = Get.find();

  final input = TextEditingController();
  final scroll = ScrollController();
  final canSend = false.obs;
  final sending = false.obs;
  final error = RxnString();

  ChatController(this.person);

  List<ChatMessage> get messages => _messages.messagesWith(person);

  /// Ainda sem o histórico completo (a lista de conversas só traz a última mensagem).
  bool get loading => !_messages.isLoaded(person) && _messages.isLoading(person);

  @override
  void onInit() {
    super.onInit();
    input.addListener(() => canSend.value = input.text.trim().isNotEmpty);
    load();
  }

  Future<void> load() async {
    error.value = null;
    try {
      await _messages.load(person);
    } catch (e) {
      error.value = errorMessage(e);
    }
  }

  Future<void> send() async {
    if (!canSend.value) return;
    if (await _send(input.text)) input.clear();
  }

  /// Envia uma resposta rápida sem mexer no que já está digitado.
  Future<void> sendPreset(String text) => _send(text);

  Future<bool> _send(String text) async {
    if (sending.value) return false;
    sending.value = true;
    try {
      await _messages.send(person, text);
      // A lista é invertida: a posição 0 é a mensagem mais recente.
      if (scroll.hasClients) {
        scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
      return true;
    } catch (e) {
      // O texto fica no campo para tentar de novo.
      showMessage(errorMessage(e), error: true);
      return false;
    } finally {
      sending.value = false;
    }
  }

  @override
  void onClose() {
    input.dispose();
    scroll.dispose();
    super.onClose();
  }
}
