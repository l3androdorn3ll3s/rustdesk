import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class TechnicianCentralSession extends ChangeNotifier {
  TechnicianCentralSession._();

  static final TechnicianCentralSession instance = TechnicianCentralSession._();

  static const String _configuredApiBaseUrl =
      String.fromEnvironment('REMOTE_SUPPORT_API_BASE_URL');

  TechnicianCentralIdentity? _identity;
  String? _sessionToken;
  DateTime? _expiresAtUtc;

  TechnicianCentralIdentity? get identity => _identity;

  bool get hasSession =>
      _identity != null && _sessionToken != null && _sessionToken!.isNotEmpty;

  Future<TechnicianCentralLoginResult> login(
    String username,
    String password,
  ) async {
    final baseUri = _tryGetApiBaseUri();

    if (baseUri == null) {
      return const TechnicianCentralLoginResult.failure(
        'O servidor central não está configurado com uma URL HTTPS válida.',
      );
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(
        baseUri.resolve('/api/auth/technicians/login'),
      );

      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.acceptHeader,
        ContentType.json.mimeType,
      );

      request.write(
        jsonEncode(
          {
            'username': username.trim(),
            'password': password,
          },
        ),
      );

      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode != HttpStatus.ok) {
        if (response.statusCode == HttpStatus.unauthorized) {
          return const TechnicianCentralLoginResult.failure(
            'Usuário ou senha inválidos.',
          );
        }

        return const TechnicianCentralLoginResult.failure(
          'Não foi possível autenticar no servidor central.',
        );
      }

      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic>) {
        return const TechnicianCentralLoginResult.failure(
          'A resposta do servidor central é inválida.',
        );
      }

      final sessionToken = decoded['sessionToken'];
      final expiresAtText = decoded['expiresAtUtc'];
      final id = decoded['id'];
      final returnedUsername = decoded['username'];
      final displayName = decoded['displayName'];
      final rolesValue = decoded['roles'];

      if (sessionToken is! String ||
          sessionToken.isEmpty ||
          expiresAtText is! String ||
          id is! String ||
          returnedUsername is! String ||
          displayName is! String ||
          rolesValue is! List) {
        return const TechnicianCentralLoginResult.failure(
          'A resposta do servidor central é inválida.',
        );
      }

      final expiresAtUtc = DateTime.tryParse(expiresAtText)?.toUtc();

      if (expiresAtUtc == null) {
        return const TechnicianCentralLoginResult.failure(
          'A resposta do servidor central é inválida.',
        );
      }

      final roles = rolesValue.whereType<String>().toList(growable: false);

      final identity = TechnicianCentralIdentity(
        id: id,
        username: returnedUsername,
        displayName: displayName,
        roles: roles,
      );

      _sessionToken = sessionToken;
      _expiresAtUtc = expiresAtUtc;
      _identity = identity;
      notifyListeners();

      return TechnicianCentralLoginResult.success(identity);
    } on HandshakeException {
      return const TechnicianCentralLoginResult.failure(
        'Falha ao estabelecer a conexão HTTPS segura com o servidor central.',
      );
    } on SocketException {
      return const TechnicianCentralLoginResult.failure(
        'Não foi possível conectar ao servidor central.',
      );
    } on FormatException {
      return const TechnicianCentralLoginResult.failure(
        'A resposta do servidor central é inválida.',
      );
    } catch (_) {
      return const TechnicianCentralLoginResult.failure(
        'Não foi possível autenticar no servidor central.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<TechnicianAgentConnectionResult> resolveAgentConnection({
    required String deviceId,
    required String capability,
  }) async {
    final baseUri = _tryGetApiBaseUri();
    final sessionToken = _sessionToken;

    if (baseUri == null) {
      return const TechnicianAgentConnectionResult.failure(
        'O servidor central não está configurado com uma URL HTTPS válida.',
      );
    }

    if (sessionToken == null || sessionToken.isEmpty) {
      return const TechnicianAgentConnectionResult.failure(
        'Sua sessão não está ativa. Entre novamente.',
      );
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(
        baseUri.resolve('/api/agents/connect'),
      );

      request.headers.contentType = ContentType.json;
      request.headers.set(
        HttpHeaders.acceptHeader,
        ContentType.json.mimeType,
      );
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $sessionToken',
      );

      request.write(
        jsonEncode(
          {
            'deviceId': deviceId,
            'capability': capability,
          },
        ),
      );

      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode == HttpStatus.unauthorized) {
        _clearSession();

        return const TechnicianAgentConnectionResult.failure(
          'Sua sessão expirou ou foi encerrada. Entre novamente.',
        );
      }

      if (response.statusCode == HttpStatus.forbidden) {
        return const TechnicianAgentConnectionResult.failure(
          'Seu usuário não possui permissão para esta operação.',
        );
      }

      if (response.statusCode != HttpStatus.ok) {
        return const TechnicianAgentConnectionResult.failure(
          'Não foi possível liberar a conexão com este equipamento.',
        );
      }

      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic>) {
        return const TechnicianAgentConnectionResult.failure(
          'A resposta do servidor central é inválida.',
        );
      }

      final returnedDeviceId = decoded['deviceId'];
      final connectionPassword = decoded['connectionPassword'];

      if (returnedDeviceId is! String ||
          returnedDeviceId.isEmpty ||
          connectionPassword is! String ||
          connectionPassword.isEmpty) {
        return const TechnicianAgentConnectionResult.failure(
          'A resposta do servidor central é inválida.',
        );
      }

      return TechnicianAgentConnectionResult.success(
        TechnicianAgentConnection(
          deviceId: returnedDeviceId,
          connectionPassword: connectionPassword,
        ),
      );
    } on HandshakeException {
      return const TechnicianAgentConnectionResult.failure(
        'Falha ao estabelecer a conexão HTTPS segura com o servidor central.',
      );
    } on SocketException {
      return const TechnicianAgentConnectionResult.failure(
        'Não foi possível conectar ao servidor central.',
      );
    } on FormatException {
      return const TechnicianAgentConnectionResult.failure(
        'A resposta do servidor central é inválida.',
      );
    } catch (_) {
      return const TechnicianAgentConnectionResult.failure(
        'Não foi possível liberar a conexão com este equipamento.',
      );
    } finally {
      client.close(force: true);
    }
  }

  void logout() {
    _clearSession();
  }

  Uri? _tryGetApiBaseUri() {
    final raw = _configuredApiBaseUrl.trim();

    if (raw.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(raw);

    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }

    return uri;
  }

  void _clearSession() {
    final hadSession =
        _identity != null || _sessionToken != null || _expiresAtUtc != null;

    _identity = null;
    _sessionToken = null;
    _expiresAtUtc = null;

    if (hadSession) {
      notifyListeners();
    }
  }
}

class TechnicianCentralIdentity {
  const TechnicianCentralIdentity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.roles,
  });

  final String id;
  final String username;
  final String displayName;
  final List<String> roles;
}

class TechnicianCentralLoginResult {
  const TechnicianCentralLoginResult._({
    required this.succeeded,
    required this.identity,
    required this.message,
  });

  const TechnicianCentralLoginResult.failure(
    String message,
  ) : this._(
          succeeded: false,
          identity: null,
          message: message,
        );

  const TechnicianCentralLoginResult.success(
    TechnicianCentralIdentity identity,
  ) : this._(
          succeeded: true,
          identity: identity,
          message: null,
        );

  final bool succeeded;
  final TechnicianCentralIdentity? identity;
  final String? message;
}

class TechnicianAgentConnection {
  const TechnicianAgentConnection({
    required this.deviceId,
    required this.connectionPassword,
  });

  final String deviceId;
  final String connectionPassword;

  @override
  String toString() {
    return 'TechnicianAgentConnection('
        'deviceId: $deviceId, '
        'connectionPassword: [REDACTED])';
  }
}

class TechnicianAgentConnectionResult {
  const TechnicianAgentConnectionResult._({
    required this.succeeded,
    required this.connection,
    required this.message,
  });

  const TechnicianAgentConnectionResult.failure(
    String message,
  ) : this._(
          succeeded: false,
          connection: null,
          message: message,
        );

  const TechnicianAgentConnectionResult.success(
    TechnicianAgentConnection connection,
  ) : this._(
          succeeded: true,
          connection: connection,
          message: null,
        );

  final bool succeeded;
  final TechnicianAgentConnection? connection;
  final String? message;
}
