import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/messages_service.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../home/profile_sheet.dart';
import 'conversations_controller.dart';

/// Aba "Mensagens": conversas com motoristas e passageiros das suas caronas.
class ConversationsView extends GetView<ConversationsController> {
  const ConversationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Row(
            children: [
              ModePill(icon: Icons.chat_bubble_outline_rounded, label: 'Mensagens'),
              Spacer(),
              SquareIconButton(
                icon: Icons.person_outline_rounded,
                background: AppColors.surfaceMuted,
                tooltip: 'Perfil',
                onPressed: showProfileSheet,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.search,
            decoration: InputDecoration(
              hintText: 'Buscar conversas...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              fillColor: AppColors.primarySoft,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final list = controller.conversations;
            if (!controller.hasAny && controller.loading) return const LoadingView();
            if (!controller.hasAny && controller.error != null) {
              return AppCard(child: MessageView.error(controller.error!, controller.reload));
            }
            if (!controller.hasAny) {
              return const AppCard(
                child: MessageView(
                  icon: Icons.forum_outlined,
                  title: 'Nenhuma conversa ainda',
                  subtitle: 'Motoristas e passageiros das suas caronas aparecem aqui.',
                ),
              );
            }
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Ninguém encontrado com esse nome.', style: mutedStyle, textAlign: TextAlign.center),
              );
            }
            return Column(
              children: [
                for (final c in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ConversationTile(conversation: c, onTap: () => controller.open(c)),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final last = conversation.last;
    final time = last == null
        ? ''
        : isSameDay(last.sentAt, DateTime.now())
            ? DateFormat.Hm().format(last.sentAt)
            : DateFormat('dd/MM').format(last.sentAt);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 18),
      child: Row(
        children: [
          Avatar(name: conversation.person.name, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  last == null ? 'Diga oi!' : '${last.fromMe ? 'Você: ' : ''}${last.text}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
