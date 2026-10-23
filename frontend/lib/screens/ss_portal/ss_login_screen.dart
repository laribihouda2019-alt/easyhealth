import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';
import '../../models/user_model.dart';
import 'ss_portal_main_screen.dart';

class SSPortalLoginScreen extends StatefulWidget {
  const SSPortalLoginScreen({super.key});

  @override
  State<SSPortalLoginScreen> createState() => _SSPortalLoginScreenState();
}

class _SSPortalLoginScreenState extends State<SSPortalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = AuthService().currentUser;
      if (user?.role != UserRole.socialSecurity && 
          user?.role != UserRole.medicalController && 
          user?.role != UserRole.admin) {
        throw 'Accès refusé. Ce portail est réservé au personnel de la Sécurité Sociale.';
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SSPortalMainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formal Blue/Grey Palette for SS Portal
    final ssPrimary = const Color(0xFF1A3B5D); 
    final ssBackground = const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: ssBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ssPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 64,
                            color: ssPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Portail Staff',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ssPrimary,
                          ),
                        ),
                        Text(
                          'Sécurité Sociale (CNAS)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Identifiant Agent',
                            prefixIcon: Icon(Icons.badge_outlined, color: ssPrimary),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(Icons.vpn_key_outlined, color: ssPrimary),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Se connecter au portail',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                          color: ssPrimary,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Retour vers l\'application',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


