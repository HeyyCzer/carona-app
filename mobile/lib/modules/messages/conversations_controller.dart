import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../app/routes.dart';
import '../../services/messages_service.dart';
import '../home/home_controller.dart';

class ConversationsController extends GetxController {
  final MessagesService _messages = Get.find();

  final search = TextEditingController();
  final _term = ''.obs;

  @override
  void onInit() {
    super.onInit();
    search.addListener(() => _term.value = search.text.trim().toLowerCase());
    ever(Get.find<HomeController>().tab, (HomeTab tab) {
      if (tab == HomeTab.messages) reload();
    });
  }

  /// Lida dentro de Obx: reage tanto à busca quanto a novas mensagens.
  List<Conversation> get conversations {
    final term = _term.value;
    final all = _messages.conversations;
    if (term.isEmpty) return all;
    return all.where((c) => c.person.name.toLowerCase().contains(term)).toList();
  }

  bool get hasAny => _messages.conversations.isNotEmpty;

  bool get loading => _messages.loading.value;

  String? get error => _messages.error.value;

  Future<void> reload() => _messages.refreshConversations();

  void open(Conversation c) => Get.toNamed(Routes.chat, arguments: c.person);

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
