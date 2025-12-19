import 'package:flutter/material.dart';

import 'services/backend_api.dart';

class ResetPasswordCodeScreen extends StatefulWidget {
  const ResetPasswordCodeScreen({super.key});

  @override
  State<ResetPasswordCodeScreen> createState() => _ResetPasswordCodeScreenState();
}

class _ResetPasswordCodeScreenState extends State<ResetPasswordCodeScreen> {
  final BackendApi _api = BackendApi();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _submitting = false;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _emailCtrl.text = args.trim();
    }
    _prefilled = true;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Email invalide.');
      return;
    }
    if (code.length != 6) {
      _showMessage('Le code doit contenir 6 chiffres.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Le mot de passe doit contenir au moins 8 caracteres.');
      return;
    }
    if (password != confirm) {
      _showMessage('Les mots de passe doivent etre identiques.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _api.confirmPasswordReset(
        email: email,
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      _showMessage('Mot de passe mis a jour.');
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _resendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Email invalide.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await _api.requestPasswordResetCode(email: email);
      if (!mounted) return;
      if (result.code != null && result.code!.isNotEmpty) {
        _showMessage('Email non configure. Code: ${result.code}');
      } else if (result.emailSent) {
        _showMessage('Nouveau code envoye.');
      } else {
        _showMessage('Code genere.');
      }
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2C3A4B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Verifier le code',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3C4D),
              ),
              textAlign: TextAlign.center,
            ),
            Container(
              height: 4,
              width: 80,
              margin: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                gradient: LinearGradient(
                  colors: [Color(0xFF21C7A8), Color(0xFF00A4E1)],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Entrez le code recu par e-mail et choisissez un nouveau mot de passe.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF5B6772),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF03A9F4), Color(0xFF00C8A0)],
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Text(
                    'Adresse e-mail',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3A4B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'votre@email.com',
                      filled: true,
                      fillColor: const Color(0xFFF7F9FB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFF00B8A9),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Code',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3A4B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '123456',
                      filled: true,
                      fillColor: const Color(0xFFF7F9FB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFF00B8A9),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _submitting ? null : _resendCode,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Renvoyer le code'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nouveau mot de passe',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3A4B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PasswordField(
                    controller: _passwordCtrl,
                    label: 'Mot de passe',
                    show: _showPassword,
                    onToggle: () => setState(() => _showPassword = !_showPassword),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Confirmer le mot de passe',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3A4B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PasswordField(
                    controller: _confirmCtrl,
                    label: 'Confirmer le mot de passe',
                    show: _showConfirm,
                    onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B8A9), Color(0xFF0AA5F6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Reinitialiser le mot de passe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: const Color(0xFFF7F9FB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF00B8A9),
            width: 1.4,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF7A8794),
          ),
        ),
      ),
    );
  }
}
