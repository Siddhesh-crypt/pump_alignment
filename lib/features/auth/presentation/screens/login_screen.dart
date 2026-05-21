import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../auth_service.dart';
import '../../domain/auth_service.dart' hide AuthService;
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identityCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await AuthService.instance.loginUser(
      _identityCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        widget.onLoginSuccess();
      } else {
        setState(() => _errorMessage = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Icon Header
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_person_rounded, size: 40, color: cs.primary),
                  ),
                  const Gap(24),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  const Gap(8),
                  Text(
                    'Sign in to access your premium alignment tools',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Gap(40),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: cs.error, size: 20),
                          const Gap(12),
                          Expanded(child: Text(_errorMessage!, style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Gap(20),
                  ],

                  TextFormField(
                    controller: _identityCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email or Username',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: cs.surfaceContainerLowest,
                    ),
                    validator: (v) => v!.isEmpty ? 'Please enter your email or username' : null,
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.password_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: cs.surfaceContainerLowest,
                    ),
                    validator: (v) => v!.isEmpty ? 'Please enter your password' : null,
                  ),
                  const Gap(32),

                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Secure Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Gap(24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New to Pump Alignment?', style: TextStyle(color: cs.onSurfaceVariant)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}