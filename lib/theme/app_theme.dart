import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C3FFF);
  static const Color primaryLight = Color(0xFF9D6FFF);
  static const Color secondary = Color(0xFF00D4FF);
  static const Color accent = Color(0xFFFFD700);

  static const Color bgDark = Color(0xFF0A0A1A);
  static const Color bgCard = Color(0xFF13132A);
  static const Color bgSurface = Color(0xFF1C1C3A);

  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9090BB);
  static const Color textHint = Color(0xFF5A5A80);

  // Light Theme Tokens (Warm, high contrast for HCI)
  static const Color lightBg = Color(0xFFFAF8F5);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF2C241E);

  static const Color xpBar = Color(0xFF00E676);
  static const Color hpBar = Color(0xFFFF3D71);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF3A8EFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [bgDark, Color(0xFF0D0D2B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightBgGradient = LinearGradient(
    colors: [Color(0xFFFDFCF9), Color(0xFFF2ECE4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class GlassScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  const GlassScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment(-0.8, -0.6),
                  radius: 1.5,
                  colors: [Color(0xFF1E0A3C), Colors.black],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF5EFE6)],
                ),
        ),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
