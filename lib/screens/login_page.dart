import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  int _errorShakeKey = 0;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  double _passwordStrength = 0.0;
  Color _strengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_evaluateEmail);
    _passwordCtrl.addListener(_evaluatePassword);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Clears the red error state as soon as the user edits any field.
  void _clearErrorIfNeeded() {
    if (_errorShakeKey > 0 || _errorMessage != null) {
      setState(() {
        _errorShakeKey = 0;
        _errorMessage = null;
      });
    }
  }

  void _evaluateEmail() {
    final valid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailCtrl.text);
    _clearErrorIfNeeded();
    if (_isEmailValid != valid) setState(() => _isEmailValid = valid);
  }

  void _evaluatePassword() {
    final text = _passwordCtrl.text;
    double strength = 0;
    Color color = Colors.transparent;
    bool valid = false;

    if (text.isEmpty) {
      strength = 0;
    } else if (text.length < 5) {
      strength = 0.33;
      color = const Color(0xFFF44336);
    } else if (text.length < 8) {
      strength = 0.66;
      color = const Color(0xFFFFC331);
    } else {
      strength = 1.0;
      color = const Color(0xFF00E5FF);
      valid = true;
    }

    _clearErrorIfNeeded();
    if (_passwordStrength != strength ||
        _strengthColor != color ||
        _isPasswordValid != valid) {
      setState(() {
        _passwordStrength = strength;
        _strengthColor = color;
        _isPasswordValid = valid;
      });
    }
  }

  void _triggerErrorShake(String msg) {
    HapticFeedback.vibrate();

    if (msg.contains('invalid-credential') ||
        msg.contains('user-not-found') ||
        msg.contains('wrong-password')) {
      msg = "Access Denied: Incorrect Email/Password or Unregistered Account.";
    } else if (msg.contains('email-already-in-use')) {
      msg = "Access Denied: This email is already registered.";
    } else if (msg.contains('too-many-requests')) {
      msg = "System Lockdown: Too many failed attempts. Try again later.";
    } else if (msg.contains('Timeout')) {
      msg = 'Quest Server Unreachable. Check your connection, Hero!';
    }

    setState(() {
      _errorMessage = msg;
      _errorShakeKey++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
              fontFamily: GoogleFonts.cambo().fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E0A3C).withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _triggerErrorShake('Please fill out required fields correctly.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = context.read<DatabaseService>();
      final userModel = context.read<UserModel>();

      await db
          .loginUser(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
            userModel: userModel,
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on TimeoutException {
      _triggerErrorShake('Timeout');
    } catch (e) {
      _triggerErrorShake(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Social auth methods removed.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildTopRow(isDark),
              const SizedBox(height: 10),
              _buildLogo(),
              const SizedBox(height: 16),
              Text(
                'Level Up Your \nProgramming Skills',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GoogleFonts.kumarOne().fontFamily,
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              Animate(
                key: ValueKey(_errorShakeKey),
                effects: [
                  if (_errorShakeKey > 0) ...[
                    const ShakeEffect(
                        hz: 8,
                        curve: Curves.easeInOut,
                        offset: Offset(10, 0),
                        duration: Duration(milliseconds: 500)),
                    const ShimmerEffect(
                        color: Color(0xFFF44336),
                        duration: Duration(milliseconds: 500)),
                  ]
                ],
                child: _buildMainCard(isDark),
              ),
              const SizedBox(height: 40),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: isDark ? Colors.white70 : AppColors.lightText.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 4),
        Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return Switch.adaptive(
              value: themeService.isDarkMode,
              activeColor: const Color(0xFF00E5FF),
              onChanged: (v) => themeService.toggleDarkMode(v),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 5,
          )
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.sports_esports,
          size: 48,
          color: Color(0xFF00E5FF),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildMainCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _errorShakeKey > 0
                ? const Color(0xFFF44336).withOpacity(0.2)
                : const Color(0xFF00E5FF).withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: _errorShakeKey > 0
                      ? const Color(0xFFF44336).withOpacity(0.5)
                      : isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white.withOpacity(0.8),
                  width: 1.5),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AnimatedOpacity(
                    duration: 400.ms,
                    opacity: _isLoading ? 0.3 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isLoading,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _emailCtrl,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            isValid: _isEmailValid,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),
                          _buildInputField(
                            controller: _passwordCtrl,
                            hint: 'Password',
                            icon: Icons.vpn_key_outlined,
                            obscure: _obscurePassword,
                            isValid: _isPasswordValid,
                            isDark: isDark,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.lightText.withOpacity(0.5),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: 300.ms,
                            width: double.infinity,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: isDark ? Colors.white10 : Colors.black26,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _passwordStrength,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: _strengthColor,
                                  boxShadow: [
                                    BoxShadow(
                                        color: _strengthColor.withOpacity(0.8),
                                        blurRadius: 10)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                'Forgot Password',
                                style: TextStyle(
                                    fontFamily: GoogleFonts.cambo().fontFamily,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.5)
                                        : AppColors.lightText.withOpacity(0.5),
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFFD9D9D9).withOpacity(0.4)
                            : AppColors.primary.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        side: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : Colors.white.withOpacity(0.2)),
                      ),
                      child: _isLoading
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF00E5FF)
                                          .withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2)
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF00E5FF)),
                            ).animate().fadeIn()
                          : Text(
                              'LOGIN',
                              style: TextStyle(
                                  fontFamily: GoogleFonts.cambo().fontFamily,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 2.0),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                            fontFamily: GoogleFonts.cambo().fontFamily,
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : AppColors.lightText.withOpacity(0.5),
                            fontSize: 14,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 600.ms).fadeIn();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    bool isValid = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
          fontFamily: GoogleFonts.cambo().fontFamily,
          color: isDark ? Colors.white : AppColors.lightText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: GoogleFonts.cambo().fontFamily,
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : AppColors.lightText.withOpacity(0.5)),
        prefixIcon: Icon(icon,
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : AppColors.lightText.withOpacity(0.5),
            size: 22),
        suffixIconConstraints: const BoxConstraints(minWidth: 80, maxHeight: 48),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isValid)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.6),
                        blurRadius: 10)
                  ],
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF00E5FF), size: 20),
              ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5)),
            if (suffix != null) suffix,
            if (suffix == null && !isValid) const SizedBox(width: 48),
          ],
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFFD9D9D9).withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      ),
    );
  }
}
