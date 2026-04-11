import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to CodeQuest',
      'body': 'Embark on an epic journey to master programming. Learn, play, and conquer challenges in a world driven by code.',
      'icon': Icons.sports_esports_rounded,
      'color': const Color(0xFF00E5FF),
    },
    {
      'title': 'Gamified Learning',
      'body': 'Earn XP for every question you answer correctly. Level up your profile to unlock exclusive titles and badges.',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFFFD700),
    },
    {
      'title': 'Climb the Leaderboard',
      'body': 'Compete with fellow heroes! Show off your achievements and climb to the top of the ranks across the globe.',
      'icon': Icons.emoji_events_rounded,
      'color': const Color(0xFF8A38F5),
    },
  ];

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Go to Login Page
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_onboarding', true);
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(
                    title: page['title'],
                    body: page['body'],
                    icon: page['icon'],
                    color: page['color'],
                    isDark: isDark,
                  );
                },
              ),
            ),
            _buildBottomControls(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String body,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Icon(icon, size: 70, color: color),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 50),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.kumarOne(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 26,
            ),
          ).animate(delay: 200.ms).slideY(begin: 0.2).fadeIn(),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.cambo(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 16,
              height: 1.5,
            ),
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primary
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                style: GoogleFonts.cambo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
