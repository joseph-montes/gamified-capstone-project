import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_page.dart';
import 'screens/onboarding_screen.dart';
import 'screens/register_page.dart';
import 'screens/main_screen.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'models/user_model.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// ─────────────────────────────────────────────
//  App Theme
//  IMPORTANT: Every TextStyle in a component theme (hintStyle, titleTextStyle,
//  contentTextStyle, button textStyle, etc.) MUST have the same `inherit` value
//  in BOTH dark and light themes. GoogleFonts.poppins() produces inherit:false,
//  so we use TextStyle(fontFamily:_poppins, inherit:true) everywhere to avoid
//  the "Failed to interpolate TextStyles with different inherit values" assert
//  that fires inside TextStyle.lerp() during any theme transition.
// ─────────────────────────────────────────────
class AppTheme {
  // Single shared font family string – avoids building a full TextStyle just
  // for the fontFamily, and ensures both themes use *identical* font objects.
  static final String _poppins = GoogleFonts.poppins().fontFamily!;

  // Shared textTheme base: BOTH themes must derive from the *same* base so
  // every TextStyle slot has identical `inherit` values before colors are applied.
  static final TextTheme _baseTextTheme =
      GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

  // ── Helper: safe Poppins TextStyle with inherit:true ──────────────────────
  // Using TextStyle() directly (not GoogleFonts.poppins()) ensures inherit:true
  // so TextStyle.lerp() never throws between the two themes.
  static TextStyle _pt({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: _poppins,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        inherit: true, // explicit — prevents lerp mismatch
      );

  // ── Shared component themes ───────────────────────────────────────────────
  // Defining _inputBorders, _cardShape, etc. once prevents accidental drift
  // between dark and light variants.

  static InputDecorationTheme _inputTheme({
    required Color fillColor,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        hintStyle: _pt(color: AppColors.textHint, fontSize: 14),
        labelStyle: _pt(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.35), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.hpBar, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      );

  // elevatedButtonTheme must be defined in BOTH themes with the same TextStyle
  // inherit value, otherwise ThemeData.lerp crashes.
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: _pt(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 0,
    ),
  );

  // snackBarTheme must also be mirrored in BOTH themes.
  static SnackBarThemeData _snackTheme({required Color contentColor}) =>
      SnackBarThemeData(
        backgroundColor: AppColors.bgCard,
        contentTextStyle: _pt(color: contentColor),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.bgSurface,
        error: AppColors.hpBar,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: _inputTheme(fillColor: AppColors.bgSurface),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            _pt(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      snackBarTheme: _snackTheme(contentColor: AppColors.textPrimary),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        error: AppColors.hpBar,
        onSurface: AppColors.lightText,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: AppColors.lightText,
        displayColor: AppColors.lightText,
      ),
      inputDecorationTheme: _inputTheme(fillColor: Colors.white),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            _pt(color: AppColors.lightText, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
      // Mirror BOTH component themes — even with same values — so lerp always
      // sees matching inherit:true on both sides.
      elevatedButtonTheme: _elevatedButtonTheme,
      snackBarTheme: _snackTheme(contentColor: AppColors.lightText),
    );
  }
}

// ─────────────────────────────────────────────
//  Entry Point
// ─────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(GamifiedLearningApp(seenOnboarding: seenOnboarding));
}

// ─────────────────────────────────────────────
//  Root Widget
// ─────────────────────────────────────────────
class GamifiedLearningApp extends StatelessWidget {
  final bool seenOnboarding;
  const GamifiedLearningApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserModel>(create: (_) => UserModel()),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'CodeQuest',
            debugShowCheckedModeBanner: false,
            themeAnimationDuration: Duration.zero,
            themeMode:
                themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            initialRoute: seenOnboarding ? '/login' : '/',
            routes: {
              '/': (_) => const OnboardingScreen(),
              '/login': (_) => const LoginPage(),
              '/register': (_) => const RegisterPage(),
              '/home': (_) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
}
