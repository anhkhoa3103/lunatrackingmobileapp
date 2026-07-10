import 'package:flutter/material.dart';
import '../l10n.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res.containsKey('token')) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (_) => false,
        );
      } else {
        setState(() => _error = res['message'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.register,
                  style: AppTheme.displayMedium),
              const SizedBox(height: 8),
              Text('Start tracking your cycle',
                  style: TextStyle(fontSize: 15,
                      color: AppColors.textSecondary(context))),
              const SizedBox(height: 40),

              _label(AppLocalizations.of(context)!.name),
              const SizedBox(height: 6),
              _textField(_nameCtrl, 'Your name',
                  TextInputType.name),
              const SizedBox(height: 16),

              _label(AppLocalizations.of(context)!.email),
              const SizedBox(height: 6),
              _textField(_emailCtrl, 'you@example.com',
                  TextInputType.emailAddress),
              const SizedBox(height: 16),

              _label(AppLocalizations.of(context)!.password),
              const SizedBox(height: 6),
              _textField(_passwordCtrl, 'Min 8 characters',
                  TextInputType.text, obscure: true),
              const SizedBox(height: 12),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppColors.subtleShadow,
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFE24B4A), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFE24B4A), fontSize: 13)),
                    ),
                  ]),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE05D6F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.register,
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary(context)));

  Widget _textField(TextEditingController ctrl, String hint,
      TextInputType type, {bool obscure = false}) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.subtleShadow,
        ),
        child: TextField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textHint(context)),
          filled: true,
          fillColor: AppColors.surface(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.cardBorder(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.cardBorder(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE05D6F)),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        ),
      );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}