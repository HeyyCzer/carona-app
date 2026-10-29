import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../services/messages_service.dart';

class ChatController extends GetxController {
  final Person person;
  final MessagesService _messages = Get.find();

  final input = TextEditingController();
  final scroll = ScrollController();
  final canSend = false.obs;

  ChatController(this.person);

  List<ChatMessage> get messages => _messages.messagesWith(person);

  @override
  void onInit() {
    super.onInit();
    input.addListener(() => canSend.value = input.text.trim().isNotEmpty);
  }

  void send() {
    if (!canSend.value) return;
    _messages.send(person, input.text);
    input.clear();
    // A lista é invertida: a posição 0 é a mensagem mais recente.
    if (scroll.hasClients) {
      scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void onClose() {
    input.dispose();
    scroll.dispose();
    super.onClose();
  }
}
