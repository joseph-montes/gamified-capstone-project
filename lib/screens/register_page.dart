import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/database_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String? _selectedYear;
  bool _isLoading = false;

  final List<String> _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year'
  ];

  // ── Fancy State Variables ──
  int _errorShakeKey = 0;
  bool _isNameValid = false;
  bool _isIdValid = false;
  bool _isEmailValid = false;
  bool _isPassValid = false;
  bool _isConfirmPassValid = false;

  double _passwordStrength = 0.0;
  Color _strengthColor = Colors.transparent;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(
        () => setState(() => _isNameValid = _nameCtrl.text.trim().length > 2));
    _idCtrl.addListener(
        () => setState(() => _isIdValid = _idCtrl.text.trim().length == 7 && int.tryParse(_idCtrl.text.trim()) != null));
    _emailCtrl.addListener(() => setState(() => _isEmailValid =
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailCtrl.text)));
    _confirmPassCtrl.addListener(() => setState(() => _isConfirmPassValid =
        _confirmPassCtrl.text.isNotEmpty &&
            _confirmPassCtrl.text == _passCtrl.text));

    _passCtrl.addListener(_evaluatePassword);
  }

  void _evaluatePassword() {
    final text = _passCtrl.text;
    double strength = 0;
    Color color = Colors.transparent;
    bool valid = false;

    if (text.isEmpty) {
      strength = 0;
    } else if (text.length < 5) {
      strength = 0.33;
      color = const Color(0xFFF44336); // Red
    } else if (text.length < 8) {
      strength = 0.66;
      color = const Color(0xFFFFC331); // Yellow
    } else {
      strength = 1.0;
      color = const Color(0xFF00E5FF); // Cyan
      valid = true;
    }

    if (_passwordStrength != strength ||
        _strengthColor != color ||
        _isPassValid != valid) {
      setState(() {
        _passwordStrength = strength;
        _strengthColor = color;
        _isPassValid = valid;
        _isConfirmPassValid = _confirmPassCtrl.text.isNotEmpty &&
            _confirmPassCtrl.text == _passCtrl.text;
      });
    }
  }

  @override
  void dispose() {
    for (var ctrl in [
      _nameCtrl,
      _idCtrl,
      _emailCtrl,
      _passCtrl,
      _confirmPassCtrl
    ]) {
      ctrl.dispose();
    }
    super.dispose();
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
      if (msg.contains('AUTH_TIMEOUT:')) {
        msg = msg.split('AUTH_TIMEOUT:').last.trim();
      } else if (msg.contains('FIRESTORE_TIMEOUT:')) {
        msg = msg.split('FIRESTORE_TIMEOUT:').last.trim();
      } else {
        msg = 'Quest Server Unreachable. Check your connection, Hero!';
      }
    }

    setState(() {
      _errorShakeKey++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.cambo(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            const Color(0xFF1E0A3C).withOpacity(0.95), // Deep space bg
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
              color: Color(0xFFF44336), width: 2), // Neon red border
        ),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _triggerErrorShake('Please fill out required fields correctly.');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _triggerErrorShake('Passwords do not match.');
      return;
    }
    if (_selectedYear == null) {
      _triggerErrorShake('Please select a year level');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = context.read<DatabaseService>();
      final userModel = context.read<UserModel>();

      await db
          .registerUser(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
            userModel: userModel,
            fullName: _nameCtrl.text.trim(),
            studentId: _idCtrl.text.trim(),
            yearLevel: _selectedYear,
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/home'); // Proceed to dashboard
      }
    } on TimeoutException {
      _triggerErrorShake('Timeout');
    } catch (e) {
      _triggerErrorShake(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 32),
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
                child: _buildRegisterCard(isDark),
              ),
              const SizedBox(height: 32),
              _buildFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : Colors.black87;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.5),
                      blurRadius: 20)
                ],
              ),
              child: const Center(
                child: Icon(Icons.sports_esports,
                    size: 36, color: Color(0xFF00E5FF)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'CodeQuest',
              style: GoogleFonts.kumarOne(color: textColor, fontSize: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Create your account and start your journey.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cambo(color: subColor, fontSize: 15),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildRegisterCard(bool isDark) {
    final iconColor = isDark ? Colors.white.withOpacity(0.5) : AppColors.lightText.withOpacity(0.5);
    final borderColor = _errorShakeKey > 0
        ? const Color(0xFFF44336).withOpacity(0.5)
        : isDark ? Colors.white.withOpacity(0.15) : const Color(0xFF00E5FF).withOpacity(0.4);
    final cardColor = isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.8);
    final dropdownFill = isDark ? const Color(0xFFD9D9D9).withOpacity(0.1) : Colors.black.withOpacity(0.04);
    final dropdownBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dropdownText = isDark ? Colors.white : AppColors.lightText;
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 1.5),
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
                          _buildField(
                              _nameCtrl, 'Full Name', Icons.person_outline,
                              isValid: _isNameValid, isDark: isDark),
                          const SizedBox(height: 16),
                          _buildField(
                              _idCtrl, 'Student ID', Icons.badge_outlined,
                              isValid: _isIdValid, isDark: isDark,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(7),
                              ]),
                          const SizedBox(height: 16),
                          _buildField(_emailCtrl, 'Email', Icons.email_outlined,
                              isValid: _isEmailValid, isDark: isDark),
                          const SizedBox(height: 16),
                          _buildField(_passCtrl, 'Password', Icons.lock_outline,
                              obscure: _obscurePass,
                              isValid: _isPassValid,
                              isDark: isDark,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                                  color: iconColor, size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              )),
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
                                    BoxShadow(color: _strengthColor.withOpacity(0.8), blurRadius: 10)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(_confirmPassCtrl, 'Confirm Password',
                              Icons.lock_reset_outlined,
                              obscure: _obscureConfirmPass,
                              isValid: _isConfirmPassValid,
                              isDark: isDark,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureConfirmPass ? Icons.visibility_off : Icons.visibility,
                                  color: iconColor, size: 20,
                                ),
                                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                              )),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedYear,
                            dropdownColor: dropdownBg,
                            style: GoogleFonts.cambo(color: dropdownText),
                            decoration: InputDecoration(
                              hintText: 'Select Year Level',
                              hintStyle: GoogleFonts.cambo(
                                  color: isDark ? Colors.white.withOpacity(0.5) : AppColors.lightText.withOpacity(0.5)),
                              filled: true,
                              fillColor: dropdownFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            ),
                            items: _yearLevels
                                .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedYear = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          'Start your learning journey and earn XP',
          style: GoogleFonts.cambo(color: const Color(0xFF00E5FF), fontSize: 16),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFFD9D9D9).withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.85),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
              side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.white.withOpacity(0.2)),
            ),
            child: _isLoading
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2)
                      ],
                    ),
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF00E5FF)),
                  ).animate().fadeIn()
                : Text(
                    'CREATE ACCOUNT',
                    style: GoogleFonts.cambo(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2.0),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Back to Login',
              style: GoogleFonts.cambo(
                  color: isDark ? Colors.white54 : AppColors.lightText.withOpacity(0.5),
                  fontSize: 14)),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    bool isValid = false,
    Widget? suffix,
    required bool isDark,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final hintColor = isDark ? Colors.white.withOpacity(0.5) : AppColors.lightText.withOpacity(0.5);
    final iconColor = isDark ? Colors.white.withOpacity(0.5) : AppColors.lightText.withOpacity(0.5);
    final fillColor = isDark ? const Color(0xFFD9D9D9).withOpacity(0.1) : Colors.black.withOpacity(0.05);
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.cambo(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cambo(color: hintColor),
        prefixIcon: Icon(icon, color: iconColor, size: 22),
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
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      ),
    );
  }
}
