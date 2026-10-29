import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Erro vindo do backend (ou de rede), com mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Cliente HTTP fino: monta URLs, injeta o token e converte erros do Spring em [ApiException].
class ApiClient {
  final String baseUrl;
  final http.Client _http;
  String? token;

  /// Chamado quando uma requisição autenticada recebe 401 (token expirado/inválido).
  void Function()? onUnauthorized;

  ApiClient(this.baseUrl, {http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Future<dynamic> get(String path, {Map<String, String?>? query}) => _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Map<String, String?>? query, Object? body}) async {
    final params = {
      for (final entry in (query ?? const {}).entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params.isEmpty ? null : params);

    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 15)),
      );
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder. Tente de novo.');
    } on SocketException {
      throw const ApiException('Sem conexão com o servidor.');
    } on http.ClientException {
      throw const ApiException('Sem conexão com o servidor.');
    }

    final text = utf8.decode(response.bodyBytes);
    final decoded = text.isEmpty ? null : _tryDecode(text);

    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    if (response.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(_errorMessage(response.statusCode, decoded), statusCode: response.statusCode);
  }

  static dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  static String _errorMessage(int status, dynamic body) {
    // Erros de validação (@Valid) vêm com mensagens genéricas em inglês; preferimos uma frase nossa.
    if (body is Map && body['errors'] is List && (body['errors'] as List).isNotEmpty) {
      return 'Confira os dados informados.';
    }
    if (body is Map && body['message'] is String && (body['message'] as String).isNotEmpty) {
      return body['message'];
    }
    return switch (status) {
      401 => 'Sua sessão expirou. Entre novamente.',
      403 => 'Você não tem permissão para isso.',
      404 => 'Não encontrado.',
      _ => 'Algo deu errado ($status).',
    };
  }
}
