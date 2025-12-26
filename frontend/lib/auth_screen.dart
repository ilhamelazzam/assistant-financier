import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'services/app_session.dart';
import 'services/backend_api.dart';
import 'services/backend_factory.dart';
import 'services/location_factory.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final BackendApi _backendApi = BackendFactory.create();

  bool isLogin = true;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool _isSubmitting = false;
  bool _locating = false;
  bool _locationFailed = false;
  String _locationHint = 'Votre ville';

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    phoneCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;
    final confirm = confirmCtrl.text;
    String? phone;
    String? location;

    if (email.isEmpty || password.isEmpty || (!isLogin && confirm.isEmpty)) {
      _showError('Veuillez renseigner l\'adresse e-mail et le mot de passe.');
      return;
    }

    if (!email.contains('@')) {
      _showError('Email invalide.');
      return;
    }

    if (!isLogin && password.length < 8) {
      _showError('Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }

    if (!isLogin && password != confirm) {
      _showError('Les mots de passe doivent être identiques.');
      return;
    }

    if (!isLogin) {
      phone = phoneCtrl.text.trim();
      if (phone.isEmpty) {
        _showError('Veuillez renseigner votre numero de telephone.');
        return;
      }
      if (locationCtrl.text.trim().isEmpty) {
        await _detectLocation(showMessage: true);
      }
      if (!mounted) return;
      location = locationCtrl.text.trim();
      if (location.isEmpty) {
        _showError('Veuillez autoriser la localisation ou saisir votre ville.');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final authResponse = isLogin
          ? await _backendApi.login(email: email, password: password)
          : await _backendApi.register(
          email: email,
          password: password,
          displayName: _displayNameFromEmail(email),
          phoneNumber: phone,
          location: location,
        );
      AppSession.instance.updateUser(authResponse);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (error) {
      _showError(_friendlyMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _ensureLocationPrefill() async {
    if (_locating) return;
    if (locationCtrl.text.trim().isNotEmpty) return;
    await _detectLocation(showMessage: false);
  }

  Future<void> _detectLocation({required bool showMessage}) async {
    final stub = LocationFactory.resolver;
    if (stub != null) {
      final value = await stub();
      if (value != null && value.isNotEmpty) {
        locationCtrl.text = value;
        _locationFailed = false;
        _locationHint = 'Votre ville';
      } else {
        _setManualFallback('Saisissez votre ville manuellement.');
      }
      return;
    }

    if (_locating) return;
    if (!mounted) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showMessage) {
          _showError('Activez la localisation de votre appareil.');
        }
        _setManualFallback('Activez la localisation ou saisissez votre ville.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (showMessage) {
          _showError('Autorisation de localisation refusee.');
        }
        _setManualFallback('Autorisez la localisation ou saisissez votre ville.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 5));
      final value = await _resolveLocation(position);
      if (value == null || value.isEmpty) {
        if (showMessage) {
          _showError('Ville introuvable pour ces coordonnees.');
        }
        _setManualFallback('Saisissez votre ville manuellement.');
        return;
      }
      locationCtrl.text = value;
      _locationFailed = false;
      _locationHint = 'Votre ville';
      if (showMessage) {
        _showMessage('Localisation detectee.');
      }
    } on TimeoutException {
      if (showMessage) {
        _showError('DÇ¸lai depasse. Saisissez votre ville manuellement.');
      }
      _setManualFallback('Saisissez votre ville manuellement.');
    } catch (error) {
      if (showMessage) {
        _showError('Detection impossible : $error');
      }
      _setManualFallback('Saisissez votre ville manuellement.');
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  void _setManualFallback(String hint) {
    if (!mounted) return;
    setState(() {
      _locationFailed = true;
      _locationHint = hint;
    });
  }

  Future<String?> _resolveLocation(Position position) async {
    final local = await _resolveWithGeocoding(position);
    if (local != null && local.isNotEmpty) {
      return local;
    }
    return _resolveWithHttp(position);
  }

  Future<String?> _resolveWithGeocoding(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return null;
      }
      final place = placemarks.first;
      final city = place.locality?.trim().isNotEmpty == true
          ? place.locality
          : (place.subAdministrativeArea?.trim().isNotEmpty == true
              ? place.subAdministrativeArea
              : place.administrativeArea);
      final country = place.country?.trim().isNotEmpty == true ? place.country : null;
      final value = [city, country].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveWithHttp(Position position) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
      });
      final response = await http.get(
        uri,
        headers: const {
          'Accept-Language': 'fr',
        },
      );
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      String? city;
      String? country;
      final address = data['address'];
      if (address is Map) {
        city = address['city'] as String? ??
            address['town'] as String? ??
            address['village'] as String? ??
            address['municipality'] as String? ??
            address['state'] as String?;
        country = address['country'] as String?;
      }
      final value = [city, country].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
      if (value.isNotEmpty) {
        return value;
      }
      final displayName = data['display_name'] as String?;
      if (displayName != null && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) => _showMessage(message);

  String _friendlyMessage(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'E-mail ou mot de passe incorrect.';
    }
    if (lower.contains('400') || lower.contains('bad request')) {
      return 'Champs invalides. Verifiez email, mot de passe, telephone et localisation.';
    }
    if (lower.contains('409') || lower.contains('conflit') || lower.contains('conflict')) {
      return 'Un compte existe deja avec cet e-mail.';
    }
    return message;
  }

  String _displayNameFromEmail(String email) {
    final atIndex = email.indexOf('@');
    final base = atIndex > 0 ? email.substring(0, atIndex) : email;
    if (base.isEmpty) {
      return 'Utilisateur';
    }
    final normalized = base[0].toUpperCase() + base.substring(1);
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                Text(
                  isLogin ? 'Authentification' : 'Créer un compte',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3C4D),
                  ),
                  textAlign: TextAlign.center,
                ),
                Container(
                  height: 4,
                  width: 100,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    gradient: LinearGradient(
                      colors: [Color(0xFF21C7A8), Color(0xFF00A4E1)],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isLogin
                      ? 'Connectez-vous pour accéder à votre coach financier vocal.'
                      : 'Créez votre compte et profitez de votre coach financier vocal.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF5B6772),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adresse e-mail',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3A4B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'votre@email.com',
                          filled: true,
                          fillColor: const Color(0xFFF7F9FB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
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
                      const SizedBox(height: 22),
                      const Text(
                        'Mot de passe',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3A4B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PasswordField(
                        controller: passCtrl,
                        label: 'Mot de passe',
                        show: showPassword,
                        onToggle: () => setState(() => showPassword = !showPassword),
                      ),
                      if (!isLogin) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Confirmer le mot de passe',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3A4B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PasswordField(
                          controller: confirmCtrl,
                          label: 'Confirmer le mot de passe',
                          show: showConfirmPassword,
                          onToggle: () => setState(() => showConfirmPassword = !showConfirmPassword),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Telephone',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3A4B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Votre numero',
                            filled: true,
                            fillColor: const Color(0xFFF7F9FB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
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
                        const SizedBox(height: 18),
                        const Text(
                          'Localisation',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3A4B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: locationCtrl,
                          decoration: InputDecoration(
                            hintText: _locating
                                ? 'Detection en cours...'
                                : (_locationFailed ? _locationHint : 'Votre ville'),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
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
                            suffixIcon: _locating
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    onPressed: _locating ? null : () => _detectLocation(showMessage: true),
                                    icon: const Icon(
                                      Icons.my_location,
                                      color: Color(0xFF7A8794),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/reset-password',
                            ),
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(color: Color(0xFF3D7BCF)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SizedBox(
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00B8A9), Color(0xFF0AA5F6)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
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
                                onPressed: _isSubmitting ? null : _submitAuth,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isLogin ? 'Se connecter' : 'Créer mon compte',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2C3A4B),
                                shadowColor: Colors.black.withOpacity(0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              onPressed: () {
                                final nextIsLogin = !isLogin;
                                setState(() => isLogin = nextIsLogin);
                                if (!nextIsLogin) {
                                  _ensureLocationPrefill();
                                }
                              },
                              child: Text(
                                isLogin ? "S'inscrire" : 'Déjà un compte ? Se connecter',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE8F4FF),
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: Color(0xFF03A9F4),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assistant de',
                              style: TextStyle(
                                color: Color(0xFF7A8794),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Coaching Financier Vocal',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3A4B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
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
          horizontal: 18,
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
