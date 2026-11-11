import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:primo_secreto_app/config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, List<String>> errors;

  ApiException(this.statusCode, this.message, [this.errors = const {}]);

  String? fieldError(String field) {
    final messages = errors[field];
    return messages == null || messages.isEmpty ? null : messages.first;
  }

  String describe(String fallback) {
    if (statusCode == 0 || statusCode == 413) {
      return message;
    }
    if (statusCode == 422 && errors.isNotEmpty) {
      return errors.values.first.first;
    }
    if ((statusCode == 403 || statusCode == 422) && message.isNotEmpty) {
      return message;
    }
    return fallback;
  }

  @override
  String toString() => "ApiException($statusCode): $message";
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  String? token;

  void Function()? onUnauthorized;

  Uri _uri(String path) => Uri.parse("${ApiConfig.apiUrl}$path");

  Map<String, String> get _headers => {
    "Accept": "application/json",
    if (token != null) "Authorization": "Bearer $token",
  };

  Map<String, String> get _jsonHeaders => {
    ..._headers,
    "Content-Type": "application/json",
  };

  Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) => _send(
    () => http.post(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body ?? {}),
    ),
  );

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) => _send(
    () => http.put(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body ?? {}),
    ),
  );

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) => _send(
    () => http.patch(
      _uri(path),
      headers: _jsonHeaders,
      body: jsonEncode(body ?? {}),
    ),
  );

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) => _send(
    () => http.delete(
      _uri(path),
      headers: _jsonHeaders,
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<dynamic> postForm(
    String path, {
    List<MapEntry<String, String>> fields = const [],
    List<http.MultipartFile> files = const [],
  }) {
    return _send(() async {
      final request = http.MultipartRequest("POST", _uri(path));
      request.headers.addAll(_headers);
      for (final field in fields) {
        request.files.add(
          http.MultipartFile.fromString(field.key, field.value),
        );
      }
      request.files.addAll(files);
      return http.Response.fromStream(await request.send());
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    final http.Response response;
    try {
      response = await call().timeout(Duration(seconds: 30));
    } on TimeoutException {
      throw ApiException(0, "El servidor tardó demasiado en responder.");
    } on SocketException {
      throw ApiException(0, "No se pudo conectar con el servidor.");
    } on http.ClientException {
      throw ApiException(0, "No se pudo conectar con el servidor.");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 413) {
      throw ApiException(
        413,
        "Los archivos pesan demasiado para el servidor. Elige menos imágenes o más livianas.",
      );
    }

    if (response.statusCode == 401 && token != null) {
      onUnauthorized?.call();
    }

    String message = "";
    Map<String, List<String>> errors = {};
    try {
      final body = jsonDecode(response.body);
      message = body["message"]?.toString() ?? "";
      final rawErrors = body["errors"];
      if (rawErrors is Map) {
        errors = rawErrors.map(
          (field, messages) =>
              MapEntry(field.toString(), List<String>.from(messages)),
        );
      }
    } catch (_) {}

    throw ApiException(response.statusCode, message, errors);
  }
}
