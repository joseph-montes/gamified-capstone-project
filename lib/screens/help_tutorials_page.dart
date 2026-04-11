import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class HelpTutorialsPage extends StatelessWidget {
  const HelpTutorialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    'HELP & TUTORIALS',
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : AppColors.lightText,
                      fontSize: 20,
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
                    // Card 1: How to earn XP
                    _buildInfoCard(
                      isDark: isDark,
                      glowColor: const Color(0xFF00E5FF),
                      title: 'How to earn XP',
                      leftGraphic: _buildNeonCircleIcon(Icons.star_rounded, const Color(0xFF00E5FF)),
                      items: [
                        _InfoItem(icon: Icons.star_rounded, iconColor: Colors.orange, text: 'Complete Lessons'),
                        _InfoItem(icon: Icons.local_fire_department_rounded, iconColor: Colors.deepOrange, text: 'Daily Streaks'),
                        _InfoItem(icon: Icons.edit_note_rounded, iconColor: Colors.amber, text: 'Take Quizzes'),
                        _InfoItem(icon: Icons.military_tech_rounded, iconColor: Colors.orangeAccent, text: 'Achieve Milestones'),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    // Card 2: How to solve puzzles
                    _buildInfoCard(
                      isDark: isDark,
                      glowColor: const Color(0xFF8A38F5),
                      title: 'How to complete quests',
                      leftGraphic: _buildNeonIcon(Icons.shield_rounded, const Color(0xFF8A38F5)),
                      items: [
                        _InfoItem(icon: Icons.calendar_month_rounded, iconColor: Colors.white, text: 'Explore Daily Challenges'),
                        _InfoItem(icon: Icons.search_rounded, iconColor: Colors.white, text: 'Select Problem Types'),
                        _InfoItem(icon: Icons.monetization_on_rounded, iconColor: Colors.amber, text: 'Solve & Gain Points'),
                        _InfoItem(icon: Icons.workspace_premium_rounded, iconColor: Colors.amberAccent, text: 'Earn Unique Badges'),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    // Card 3: Rankings
                    _buildInfoCard(
                      isDark: isDark,
                      glowColor: const Color(0xFF43A047), // Green/Cyan vibe for podium
                      title: 'Leaderboard & Ranks',
                      leftGraphic: _buildNeonIcon(Icons.leaderboard_rounded, const Color(0xFF00E5FF)),
                      items: [
                        _InfoItem(icon: Icons.emoji_events_rounded, iconColor: Colors.orangeAccent, text: 'Climb Rankings'),
                        _InfoItem(icon: Icons.trending_up_rounded, iconColor: Colors.white, text: 'Compare your progress'),
                        _InfoItem(icon: Icons.bar_chart_rounded, iconColor: Colors.pinkAccent, text: 'Track top performers'),
                        _InfoItem(icon: Icons.military_tech_rounded, iconColor: Colors.yellow, text: 'Advance through Levels'),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    // Card 4: FAQs
                    _buildFaqCard(context, isDark).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

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

  Widget _buildNeonCircleIcon(IconData icon, Color color) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 1)
        ],
      ),
      child: Center(
        child: Icon(icon, color: color, size: 36),
      ),
    );
  }

  Widget _buildNeonIcon(IconData icon, Color color) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 54,
          shadows: [
            Shadow(color: color.withOpacity(0.8), blurRadius: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required Color glowColor,
    required String title,
    required Widget leftGraphic,
    required List<_InfoItem> items,
  }) {
    return _HelpGlassCard(
      isDark: isDark,
      glowColor: glowColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leftGraphic,
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(item.icon, color: item.iconColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.text,
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, bool isDark) {
    return _HelpGlassCard(
      isDark: isDark,
      glowColor: Colors.white70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAQs',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Divider(color: isDark ? Colors.white24 : Colors.black12, thickness: 1.5),
          const SizedBox(height: 8),
          _buildFaqTile(context, 'How do I use CodeQuest?', 'Complete daily challenges and quizzes to earn XP. You can select your favorite programming modules from the curriculum.', isDark),
          _buildFaqTile(context, 'When does the leaderboard reset?', 'The leaderboard updates in real-time based on your accumulated XP. Stay active to hold your rank!', isDark),
          _buildFaqTile(context, 'How do I earn badges?', 'Badges are automatically awarded when you hit certain milestones like reaching a level or a daily streak!', isDark),
        ],
      ),
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer, bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: isDark ? Colors.white : Colors.black87,
        collapsedIconColor: isDark ? Colors.white : Colors.black87,
        tilePadding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final Color iconColor;
  final String text;

  _InfoItem({required this.icon, required this.iconColor, required this.text});
}

class _HelpGlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color glowColor;

  const _HelpGlassCard({
    required this.child,
    required this.isDark,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glowColor.withOpacity(0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.08),
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
