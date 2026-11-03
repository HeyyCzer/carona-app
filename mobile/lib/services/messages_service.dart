import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/carona_api.dart';
import '../api/models.dart';
import '../config.dart';
import 'auth_service.dart';

class ChatMessage {
  final int id;
  final String text;
  final DateTime sentAt;
  final bool fromMe;

  const ChatMessage({required this.id, required this.text, required this.sentAt, required this.fromMe});

  factory ChatMessage.of(Message message, int myId) =>
      ChatMessage(id: message.id, text: message.content, sentAt: message.createdAt, fromMe: message.from.id == myId);
}

class Conversation {
  final Person person;
  final List<ChatMessage> messages;

  /// Se o histórico completo já foi baixado (a lista de conversas só traz a última mensagem).
  bool loaded = false;

  Conversation(this.person, [List<ChatMessage>? messages]) : messages = messages ?? [];

  ChatMessage? get last => messages.isEmpty ? null : messages.last;

  /// Adiciona sem duplicar (a mesma mensagem pode chegar pela resposta do POST e pelo WebSocket).
  bool add(ChatMessage message) {
    if (messages.any((m) => m.id == message.id)) return false;
    messages.add(message);
    messages.sort((a, b) {
      final byDate = a.sentAt.compareTo(b.sentAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return true;
  }
}

/// Conversas com motoristas e passageiros, sincronizadas com o backend.
///
/// O histórico vem da API REST; mensagens novas (inclusive as enviadas por outro aparelho
/// da mesma conta) chegam em tempo real pelo WebSocket `/ws/messages`, que reconecta
/// sozinho quando a conexão cai.
class MessagesService extends GetxService {
  final CaronaApi api;

  /// Conversas do usuário logado, indexadas pelo id da outra pessoa.
  final _conversations = <int, Conversation>{}.obs;
  final loading = false.obs;
  final error = RxnString();
  final _loadingChats = <int>{}.obs;

  int? _ownerId;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _attempts = 0;
  bool _connectedBefore = false;
  late final AppLifecycleListener _lifecycle;

  MessagesService(this.api);

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthService>();
    _startFor(auth.user.value?.id);
    // Cada conta tem as suas conversas.
    ever(auth.user, (User? u) => _startFor(u?.id));
    // O sistema costuma derrubar o socket com o app em segundo plano; volta na hora ao reabrir.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_ownerId != null && _channel == null) _connect();
      },
    );
  }

  @override
  void onClose() {
    _lifecycle.dispose();
    _disconnect();
    super.onClose();
  }

  void _startFor(int? userId) {
    if (_ownerId == userId) return;
    _disconnect();
    _ownerId = userId;
    _conversations.clear();
    error.value = null;
    _connectedBefore = false;
    if (userId == null) return;
    refreshConversations();
    _connect();
  }

  // WebSocket

  void _connect() {
    _reconnectTimer?.cancel();
    final token = api.client.token;
    if (_ownerId == null || token == null) return;

    final uri = Uri.parse('${AppConfig.wsUrl}/ws/messages').replace(queryParameters: {'token': token});
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _onData,
      onError: (_) => _scheduleReconnect(channel),
      onDone: () => _scheduleReconnect(channel),
      cancelOnError: true,
    );
    channel.ready
        .then((_) {
          if (_channel != channel) return;
          _attempts = 0;
          // Mensagens que chegaram enquanto estava desconectado.
          if (_connectedBefore) _resync();
          _connectedBefore = true;
        })
        .catchError((_) {
          // A falha também chega pelo stream (onError), que agenda a reconexão.
        });
  }

  void _scheduleReconnect(WebSocketChannel channel) {
    if (_channel != channel) return;
    _subscription?.cancel();
    _channel = null;
    if (_ownerId == null) return;
    // Espera 1, 2, 4... até 30 segundos entre tentativas.
    final delay = Duration(seconds: min(30, 1 << min(_attempts, 5)));
    _attempts++;
    _reconnectTimer = Timer(delay, _connect);
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _attempts = 0;
  }

  void _onData(dynamic data) {
    try {
      _add(Message.fromJson(jsonDecode(data as String)));
    } catch (_) {
      // Ignora qualquer coisa que não seja uma mensagem.
    }
  }

  void _resync() {
    refreshConversations();
    for (final c in _conversations.values.where((c) => c.loaded).toList()) {
      load(c.person).catchError((_) {});
    }
  }

  // Dados

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

  bool isLoaded(Person person) => _conversations[person.id]?.loaded ?? false;

  bool isLoading(Person person) => _loadingChats.contains(person.id);

  /// Baixa a lista de conversas (com a última mensagem de cada uma).
  Future<void> refreshConversations() async {
    final owner = _ownerId;
    if (owner == null) return;
    loading.value = true;
    error.value = null;
    try {
      final summaries = await api.conversations();
      if (_ownerId != owner) return;
      for (final s in summaries) {
        final conversation = _conversations[s.person.id] ?? Conversation(s.person);
        conversation.add(ChatMessage.of(s.lastMessage, owner));
        _conversations[s.person.id] = conversation;
      }
      _conversations.refresh();
    } catch (e) {
      if (_ownerId == owner) error.value = errorMessage(e);
    } finally {
      if (_ownerId == owner) loading.value = false;
    }
  }

  /// Baixa o histórico completo da conversa com [person].
  Future<void> load(Person person) async {
    final owner = _ownerId;
    if (owner == null) return;
    _loadingChats.add(person.id);
    try {
      final messages = await api.messagesWith(person.id);
      if (_ownerId != owner) return;
      final conversation = _conversations[person.id] ?? Conversation(person);
      for (final m in messages) {
        conversation.add(ChatMessage.of(m, owner));
      }
      conversation.loaded = true;
      _conversations[person.id] = conversation;
      _conversations.refresh();
    } finally {
      _loadingChats.remove(person.id);
    }
  }

  /// Garante que as pessoas com quem o usuário tem caronas apareçam na lista.
  void addContacts(Iterable<Person> people) {
    var changed = false;
    for (final p in people) {
      if (p.id == _ownerId || _conversations.containsKey(p.id)) continue;
      _conversations[p.id] = Conversation(p);
      changed = true;
    }
    if (changed) _conversations.refresh();
  }

  /// Envia pela API REST; lança [ApiException] se o backend recusar.
  Future<void> send(Person to, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _add(await api.sendMessage(to.id, trimmed));
  }

  void _add(Message message) {
    final owner = _ownerId;
    if (owner == null) return;
    final other = message.from.id == owner ? message.to : message.from;
    final conversation = _conversations[other.id] ?? Conversation(other);
    final added = conversation.add(ChatMessage.of(message, owner));
    _conversations[other.id] = conversation;
    if (added) _conversations.refresh();
  }
}
