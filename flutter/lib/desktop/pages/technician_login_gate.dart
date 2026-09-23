import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../brand/brand_profile.dart';
import '../services/technician_central_session.dart';

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
  final _session = TechnicianCentralSession.instance;

  TechnicianCentralIdentity? _identity;
  String? _error;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    _identity = _session.identity;
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _identity = _session.identity;
      _authenticating = false;

      if (_identity == null) {
        _error = 'Sua sessão terminou. Entre novamente.';
      }
    });
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

    final result = await _session.login(
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
                            RemoteSupportBrand.logoAsset,
                            height: 82,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            RemoteSupportBrand.productName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            RemoteSupportBrand.technicianSubtitle,
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
                            onPressed: _authenticating ? null : _authenticate,
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
                            RemoteSupportBrand.centralAuthFooter,
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
