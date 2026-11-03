import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/messages_service.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final person = controller.person;
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMuted),
          onPressed: Get.back,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(name: person.name, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(person.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messages = controller.messages.reversed.toList();
              if (messages.isEmpty && controller.loading) return const LoadingView();
              if (messages.isEmpty && controller.error.value != null) {
                return MessageView.error(controller.error.value!, controller.load);
              }
              if (messages.isEmpty) {
                return MessageView(
                  icon: Icons.waving_hand_outlined,
                  title: 'Comece a conversa',
                  subtitle: 'Combine o ponto de embarque com ${person.firstName}.',
                );
              }
              return ListView.builder(
                controller: controller.scroll,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final message = messages[i];
                  // Separador de data antes da primeira mensagem de cada dia (lista invertida).
                  final older = i + 1 < messages.length ? messages[i + 1] : null;
                  final showDate = older == null || !isSameDay(older.sentAt, message.sentAt);
                  return Column(
                    children: [
                      if (showDate) _DateChip(message.sentAt),
                      _Bubble(message: message),
                    ],
                  );
                },
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.send(),
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        fillColor: AppColors.primarySoft,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  Obx(() {
                    final enabled = controller.canSend.value && !controller.sending.value;
                    return IconButton(
                      tooltip: 'Enviar',
                      onPressed: enabled ? controller.send : null,
                      icon: controller.sending.value
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.send_rounded, color: enabled ? AppColors.primary : AppColors.textHint),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;

  const _DateChip(this.date);

  @override
  Widget build(BuildContext context) {
    final label = isSameDay(date, DateTime.now())
        ? 'Hoje, ${DateFormat("d 'de' MMM", 'pt_BR').format(date)}'
        : DateFormat("EEE, d 'de' MMM", 'pt_BR').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.bubbleIncoming, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : AppColors.bubbleIncoming,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(mine ? 18 : 4),
              topRight: Radius.circular(mine ? 4 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: TextStyle(fontSize: 15, color: mine ? Colors.white : AppColors.text),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat.Hm().format(message.sentAt),
                style: TextStyle(fontSize: 11, color: mine ? Colors.white70 : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
