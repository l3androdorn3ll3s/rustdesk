import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TechnicianLoginGate extends StatefulWidget {
  const TechnicianLoginGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<TechnicianLoginGate> createState() => _TechnicianLoginGateState();
}

class _TechnicianLoginGateState extends State<TechnicianLoginGate> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = LocalTechnicianAuthService();

  LocalTechnicianIdentity? _identity;
  String? _error;
  bool _authenticating = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_authenticating) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Informe usuário e senha.';
      });
      return;
    }

    setState(() {
      _authenticating = true;
      _error = null;
    });

    try {
      final result = await _auth.authenticate(
        username,
        password,
      );

      _passwordController.clear();

      if (!mounted) {
        return;
      }

      if (!result.succeeded || result.identity == null) {
        setState(() {
          _authenticating = false;
          _error = result.message ?? 'Usuário ou senha inválidos.';
        });
        return;
      }

      setState(() {
        _identity = result.identity;
        _authenticating = false;
        _error = null;
      });
    } catch (_) {
      _passwordController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _authenticating = false;
        _error = 'Não foi possível validar as credenciais locais.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_identity != null) {
      return widget.child;
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  34,
                  28,
                  34,
                  30,
                ),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/brand_logo.png',
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'IdealSecurity Remote Support',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Acesso do técnico',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _usernameController,
                        enabled: !_authenticating,
                        autofocus: true,
                        autofillHints: const [
                          AutofillHints.username,
                        ],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Usuário',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        enabled: !_authenticating,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [
                          AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _authenticate(),
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed:
                            _authenticating ? null : _authenticate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          child: _authenticating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'As credenciais são validadas localmente neste computador. '
                        'Nenhuma conexão HTTP é utilizada neste piloto.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 56,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Tooltip(
              message: 'Fechar',
              child: IconButton(
                onPressed: () async {
                  await windowManager.setPreventClose(false);
                  await windowManager.close();
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LocalTechnicianAuthService {
  static const _storeVersion = 1;

  Future<LocalTechnicianAuthenticationResult> authenticate(
    String username,
    String password,
  ) async {
    final storeFile = _resolveStoreFile();

    if (storeFile == null || !await storeFile.exists()) {
      return const LocalTechnicianAuthenticationResult.failure(
        'Nenhum técnico local cadastrado. '
        'Use o IdealSecurity - Gerenciador de Técnicos.',
      );
    }

    final raw = await storeFile.readAsString();
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      return const LocalTechnicianAuthenticationResult.failure(
        'O cadastro local de técnicos é inválido.',
      );
    }

    final version = _readValue(decoded, 'Version', 'version');
    if (version != _storeVersion) {
      return const LocalTechnicianAuthenticationResult.failure(
        'A versão do cadastro local de técnicos não é compatível.',
      );
    }

    final rawAccounts = _readValue(decoded, 'Accounts', 'accounts');
    if (rawAccounts is! List) {
      return const LocalTechnicianAuthenticationResult.failure(
        'O cadastro local de técnicos é inválido.',
      );
    }

    Map<String, dynamic>? account;

    for (final candidate in rawAccounts) {
      if (candidate is! Map) {
        continue;
      }

      final typed = Map<String, dynamic>.from(candidate);
      final candidateUsername =
          _readString(typed, 'Username', 'username');

      if (candidateUsername != null &&
          candidateUsername.toLowerCase() == username.toLowerCase()) {
        account = typed;
        break;
      }
    }

    if (account == null) {
      return const LocalTechnicianAuthenticationResult.failure(
        'Usuário ou senha inválidos.',
      );
    }

    final saltText = _readString(account, 'Salt', 'salt');
    final hashText =
        _readString(account, 'PasswordHash', 'passwordHash');
    final iterationsValue =
        _readValue(account, 'Iterations', 'iterations');

    if (saltText == null ||
        hashText == null ||
        iterationsValue is! int ||
        iterationsValue <= 0) {
      return const LocalTechnicianAuthenticationResult.failure(
        'A credencial local deste técnico é inválida.',
      );
    }

    Uint8List salt;
    Uint8List expectedHash;

    try {
      salt = Uint8List.fromList(
        base64Decode(saltText),
      );
      expectedHash = Uint8List.fromList(
        base64Decode(hashText),
      );
    } on FormatException {
      return const LocalTechnicianAuthenticationResult.failure(
        'A credencial local deste técnico é inválida.',
      );
    }

    final verification = await Isolate.run(
      () => _verifyPassword(
        _PasswordVerificationInput(
          password: password,
          salt: salt,
          iterations: iterationsValue,
          expectedHash: expectedHash,
        ),
      ),
    );

    if (!verification) {
      return const LocalTechnicianAuthenticationResult.failure(
        'Usuário ou senha inválidos.',
      );
    }

    final id = _readString(account, 'Id', 'id') ?? username;
    final displayName =
        _readString(account, 'DisplayName', 'displayName') ?? username;
    final isAdminValue =
        _readValue(account, 'IsAdmin', 'isAdmin');

    return LocalTechnicianAuthenticationResult.success(
      LocalTechnicianIdentity(
        id: id,
        username:
            _readString(account, 'Username', 'username') ?? username,
        displayName: displayName,
        isAdmin: isAdminValue == true,
      ),
    );
  }

  File? _resolveStoreFile() {
    final localAppData = Platform.environment['LOCALAPPDATA'];

    if (localAppData == null || localAppData.trim().isEmpty) {
      return null;
    }

    return File(
      [
        localAppData,
        'RemoteSupport',
        'TechnicianConsole',
        'auth',
        'technicians.json',
      ].join(Platform.pathSeparator),
    );
  }

  static dynamic _readValue(
    Map<String, dynamic> source,
    String pascalName,
    String camelName,
  ) {
    if (source.containsKey(pascalName)) {
      return source[pascalName];
    }

    return source[camelName];
  }

  static String? _readString(
    Map<String, dynamic> source,
    String pascalName,
    String camelName,
  ) {
    final value = _readValue(
      source,
      pascalName,
      camelName,
    );

    return value is String ? value : null;
  }
}

class LocalTechnicianIdentity {
  const LocalTechnicianIdentity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.isAdmin,
  });

  final String id;
  final String username;
  final String displayName;
  final bool isAdmin;
}

class LocalTechnicianAuthenticationResult {
  const LocalTechnicianAuthenticationResult._({
    required this.succeeded,
    required this.identity,
    required this.message,
  });

  const LocalTechnicianAuthenticationResult.failure(
    String message,
  ) : this._(
          succeeded: false,
          identity: null,
          message: message,
        );

  const LocalTechnicianAuthenticationResult.success(
    LocalTechnicianIdentity identity,
  ) : this._(
          succeeded: true,
          identity: identity,
          message: null,
        );

  final bool succeeded;
  final LocalTechnicianIdentity? identity;
  final String? message;
}

class _PasswordVerificationInput {
  const _PasswordVerificationInput({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.expectedHash,
  });

  final String password;
  final Uint8List salt;
  final int iterations;
  final Uint8List expectedHash;
}

bool _verifyPassword(
  _PasswordVerificationInput input,
) {
  final actualHash = _pbkdf2HmacSha256(
    password: input.password,
    salt: input.salt,
    iterations: input.iterations,
    derivedKeyLength: input.expectedHash.length,
  );

  return _fixedTimeEquals(
    actualHash,
    input.expectedHash,
  );
}

Uint8List _pbkdf2HmacSha256({
  required String password,
  required Uint8List salt,
  required int iterations,
  required int derivedKeyLength,
}) {
  final passwordBytes = utf8.encode(password);
  final hmac = Hmac(
    sha256,
    passwordBytes,
  );

  const hashLength = 32;
  final blockCount =
      (derivedKeyLength + hashLength - 1) ~/ hashLength;

  final derived = BytesBuilder(copy: false);

  for (var blockIndex = 1;
      blockIndex <= blockCount;
      blockIndex++) {
    final initialInput = BytesBuilder(copy: false)
      ..add(salt)
      ..add([
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ]);

    var u = Uint8List.fromList(
      hmac.convert(initialInput.toBytes()).bytes,
    );

    final blockResult = Uint8List.fromList(u);

    for (var round = 1; round < iterations; round++) {
      u = Uint8List.fromList(
        hmac.convert(u).bytes,
      );

      for (var i = 0; i < blockResult.length; i++) {
        blockResult[i] ^= u[i];
      }
    }

    derived.add(blockResult);
  }

  final bytes = derived.toBytes();

  return Uint8List.fromList(
    bytes.sublist(
      0,
      derivedKeyLength,
    ),
  );
}

bool _fixedTimeEquals(
  Uint8List left,
  Uint8List right,
) {
  if (left.length != right.length) {
    return false;
  }

  var difference = 0;

  for (var i = 0; i < left.length; i++) {
    difference |= left[i] ^ right[i];
  }

  return difference == 0;
}
