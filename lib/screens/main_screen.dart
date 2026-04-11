import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';
import 'challenges_page.dart';
import 'leaderboard_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _navigateTo(int index) => setState(() => _currentIndex = index);

  List<Widget> get _pages => [
    HomePage(onNavigateToTab: _navigateTo),
    const ChallengesPage(),
    const LeaderboardPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildGlassBottomNav(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context, bool isDark) {
    // Determine screen boundary padding (helpful for Android system buttons)
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Add extra padding spacing so it doesn't overlap those buttons
    final paddingBottom = bottomInset > 0 ? bottomInset + 10.0 : 20.0;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 65 + paddingBottom,
          padding: EdgeInsets.only(bottom: paddingBottom),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.6),
            border: Border(
                top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem('Home', Icons.home_filled, 0, isDark),
              _navItem('Challenges', Icons.local_fire_department_outlined, 1, isDark),
              _navItem('Leader', Icons.bar_chart_outlined, 2, isDark),
              _navItem('Profile', Icons.person_outline, 3, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, IconData icon, int index, bool isDark) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 40 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(50),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 1)
                      ]
                    : [],
              ),
            ),
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF00E5FF)
                  : (isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.4)),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cambo(
                color: isSelected
                    ? const Color(0xFF00E5FF)
                    : (isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4)),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
