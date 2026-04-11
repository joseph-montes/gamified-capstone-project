import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/theme_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'help_tutorials_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _appNotifications = true;
  bool _dailyReminder = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = context.watch<ThemeService>();

    return GlassScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_rounded,
                          color: isDark ? Colors.white : AppColors.lightText,
                          size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : AppColors.lightText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.1),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    // Theme Settings
                    _buildSettingsCard(
                      isDark: isDark,
                      glowColor: const Color(0xFF00E5FF),
                      title: 'Theme',
                      children: [
                        _buildSwitchRow(
                          title: 'Dark Mode',
                          value: themeService.isDarkMode,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) {
                            if (val) themeService.toggleDarkMode(true);
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchRow(
                          title: 'Light Mode',
                          value: !themeService.isDarkMode,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) {
                            if (val) themeService.toggleDarkMode(false);
                          },
                          isDark: isDark,
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // Notifications Settings
                    _buildSettingsCard(
                      isDark: isDark,
                      glowColor: const Color(0xFF8A38F5),
                      title: 'Notifications', // Changed from Theme in the mock image to make more sense
                      children: [
                        _buildSwitchRow(
                          title: 'App Notifications',
                          value: _appNotifications,
                          activeColor: const Color(0xFF8A38F5),
                          onChanged: (val) => setState(() => _appNotifications = val),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchRow(
                          title: 'Daily Reminder',
                          subtitle: 'Manage challenge alerts and achievement badges.',
                          value: _dailyReminder,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) => setState(() => _dailyReminder = val),
                          isDark: isDark,
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // Account Settings
                    _buildSettingsCard(
                      isDark: isDark,
                      glowColor: const Color(0xFF00E5FF),
                      title: 'Account',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionBtn(
                                isDark: isDark,
                                icon: Icons.vpn_key_rounded,
                                iconColor: const Color(0xFF00E5FF),
                                label: 'Change\nPassword',
                                onTap: () => _showChangePasswordSheet(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionBtn(
                                isDark: isDark,
                                icon: Icons.alternate_email_rounded,
                                iconColor: const Color(0xFF00E5FF),
                                label: 'Update\nEmail',
                                onTap: () => _showChangeEmailSheet(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // Support Settings
                    _buildSettingsCard(
                      isDark: isDark,
                      glowColor: const Color(0xFF00E5FF),
                      title: 'Support',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionBtn(
                                isDark: isDark,
                                icon: Icons.support_rounded,
                                iconColor: const Color(0xFF00E5FF),
                                label: 'Help &\nTutorials',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpTutorialsPage()));
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionBtn(
                                isDark: isDark,
                                icon: Icons.help_outline_rounded,
                                iconColor: const Color(0xFF00E5FF),
                                label: 'FAQs\n',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpTutorialsPage()));
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                    const SizedBox(height: 40),
                    
                    Text(
                      'v1.2.3',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required Color glowColor,
    required String title,
    required List<Widget> children,
  }) {
    return _SettingsGlassCard(
      isDark: isDark,
      glowColor: glowColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    String? subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white38 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ]
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: activeColor,
          inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white38 : Colors.black38, size: 14),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D0D1F).withOpacity(0.97) : Colors.white.withOpacity(0.98),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Change Password',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : AppColors.lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SettingsSheetField(
                      controller: oldPassCtrl,
                      label: 'Old Password',
                      icon: Icons.lock_clock_rounded,
                      isDark: isDark,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _SettingsSheetField(
                      controller: newPassCtrl,
                      label: 'New Password',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _SettingsSheetField(
                      controller: confirmPassCtrl,
                      label: 'Confirm New Password',
                      icon: Icons.lock_reset_rounded,
                      isDark: isDark,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (oldPassCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your old password')));
                            return;
                          }
                          if (newPassCtrl.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                            return;
                          }
                          if (newPassCtrl.text != confirmPassCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          try {
                            await context.read<DatabaseService>().updatePassword(oldPassCtrl.text, newPassCtrl.text);
                            nav.pop();
                            messenger.showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                          } finally {
                            if (ctx.mounted) setModalState(() => isSaving = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text('UPDATE PASSWORD',
                                style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeEmailSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D0D1F).withOpacity(0.97) : Colors.white.withOpacity(0.98),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Update Email',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : AppColors.lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SettingsSheetField(
                      controller: emailCtrl,
                      label: 'New Email Address',
                      icon: Icons.alternate_email_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email')));
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          try {
                            final userModel = context.read<UserModel>();
                            await context.read<DatabaseService>().updateEmail(emailCtrl.text, userModel);
                            nav.pop();
                            messenger.showSnackBar(const SnackBar(content: Text('Email updated successfully!')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                          } finally {
                            if (ctx.mounted) setModalState(() => isSaving = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text('UPDATE EMAIL',
                                style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _SettingsSheetField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: isDark ? Colors.white : AppColors.lightText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: isDark ? Colors.white54 : Colors.black87, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF).withOpacity(0.8), size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

class _SettingsGlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color glowColor;

  const _SettingsGlassCard({
    required this.child,
    required this.isDark,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glowColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
