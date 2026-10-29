import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/models.dart';
import 'auth_service.dart';

class ChatMessage {
  final String text;
  final DateTime sentAt;
  final bool fromMe;

  const ChatMessage({required this.text, required this.sentAt, required this.fromMe});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        sentAt: DateTime.parse(json['sentAt']),
        fromMe: json['fromMe'],
      );

  Map<String, dynamic> toJson() => {'text': text, 'sentAt': sentAt.toIso8601String(), 'fromMe': fromMe};
}

class Conversation {
  final Person person;
  final List<ChatMessage> messages;

  Conversation(this.person, [List<ChatMessage>? messages]) : messages = messages ?? [];

  ChatMessage? get last => messages.isEmpty ? null : messages.last;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        Person.fromJson(json['person']),
        (json['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'person': person.toJson(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}

/// Conversas com motoristas e passageiros.
///
/// O backend ainda não tem endpoints de mensagens (só a permissão `message:send`),
/// então as conversas ficam salvas apenas neste aparelho. Para integrar, basta trocar
/// a persistência deste service por chamadas à API mantendo a mesma interface.
class MessagesService extends GetxService {
  final SharedPreferences prefs;

  /// Conversas do usuário logado, indexadas pelo id da outra pessoa.
  final _conversations = <int, Conversation>{}.obs;
  int? _ownerId;

  MessagesService(this.prefs);

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthService>();
    _loadFor(auth.user.value?.id);
    // Cada conta tem as suas conversas.
    ever(auth.user, (User? u) => _loadFor(u?.id));
  }

  String get _key => 'messages.$_ownerId';

  void _loadFor(int? userId) {
    if (_ownerId == userId) return;
    _ownerId = userId;
    final loaded = <int, Conversation>{};
    final raw = userId == null ? null : prefs.getString(_key);
    if (raw != null) {
      for (final c in (jsonDecode(raw) as List).map((e) => Conversation.fromJson(e))) {
        loaded[c.person.id] = c;
      }
    }
    _conversations.assignAll(loaded);
  }

  /// Conversas ordenadas pela mensagem mais recente; contatos sem mensagens vão para o fim.
  List<Conversation> get conversations {
    final list = _conversations.values.toList();
    list.sort((a, b) {
      final la = a.last?.sentAt, lb = b.last?.sentAt;
      if (la == null && lb == null) return a.person.name.compareTo(b.person.name);
      if (la == null) return 1;
      if (lb == null) return -1;
      return lb.compareTo(la);
    });
    return list;
  }

  List<ChatMessage> messagesWith(Person person) => _conversations[person.id]?.messages ?? const [];

  /// Garante que as pessoas com quem o usuário tem caronas apareçam na lista.
  void addContacts(Iterable<Person> people) {
    var changed = false;
    for (final p in people) {
      if (p.id == _ownerId || _conversations.containsKey(p.id)) continue;
      _conversations[p.id] = Conversation(p);
      changed = true;
    }
    if (changed) _save();
  }

  void send(Person to, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final conversation = _conversations[to.id] ?? Conversation(to);
    conversation.messages.add(ChatMessage(text: trimmed, sentAt: DateTime.now(), fromMe: true));
    _conversations[to.id] = conversation;
    _conversations.refresh();
    _save();
  }

  void _save() {
    if (_ownerId == null) return;
    prefs.setString(_key, jsonEncode(_conversations.values.map((c) => c.toJson()).toList()));
  }
}
