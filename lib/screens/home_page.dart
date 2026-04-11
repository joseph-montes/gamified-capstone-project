import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'dart:convert';

import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import 'challenge_screen.dart';

// ─────────────────────────────────────────────
//  HomePage – main dashboard shown after login.
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const HomePage({super.key, this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _notifOpen = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    final user = context.read<UserModel>();
    final db = context.read<DatabaseService>();
    db.notificationsStream(user).listen((notifs) {
      if (mounted) setState(() => _notifications = notifs);
    });
  }

  // Map icon string → MaterialIcon
  IconData _iconFor(String key) {
    switch (key) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'medal':
        return Icons.military_tech_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final db = context.read<DatabaseService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  _buildProfileHeader(user, isDark)
                      .animate()
                      .slideY(begin: -0.2, duration: 600.ms)
                      .fadeIn(),
                  const SizedBox(height: 28),
                  _buildXPSection(user, isDark)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 600.ms),
                  const SizedBox(height: 28),
                  _buildStatsRow(user, isDark)
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 600.ms),
                  const SizedBox(height: 28),
                  _buildDailyChallenge(user, db, isDark)
                      .animate()
                      .slideX(begin: 0.1, delay: 350.ms, duration: 600.ms)
                      .fadeIn(),
                  const SizedBox(height: 28),
                  _buildQuickActions(isDark)
                      .animate()
                      .slideY(begin: 0.2, delay: 450.ms, duration: 600.ms)
                      .fadeIn(),
                  const SizedBox(height: 28),
                  _buildAchievementsPreview(user, isDark)
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 600.ms),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          // Notification overlay panel
          if (_notifOpen) _buildNotificationPanel(isDark),
        ],
      ),
    );
  }

  // ── Profile Header ────────────────────────
  Widget _buildProfileHeader(UserModel user, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final unreadCount = _notifications.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Avatar — shows uploaded photo, falls back to default asset
          GestureDetector(
            onTap: () => widget.onNavigateToTab?.call(3),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF8A38F5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF1A1A3E),
                backgroundImage: user.photoUrl.isNotEmpty
                    ? (user.photoUrl.startsWith('data:image/')
                        ? MemoryImage(base64Decode(user.photoUrl.split(',').last))
                        : NetworkImage(user.photoUrl)) as ImageProvider
                    : const AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.fullName.isEmpty ? "Hero" : user.fullName.split(" ").first}! 👋',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Level ${user.level} • ${user.rankTitle}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: () => setState(() => _notifOpen = !_notifOpen),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _notifOpen
                          ? const Color(0xFF00E5FF)
                          : (isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.08)),
                      width: 1.3,
                    ),
                  ),
                  child: Icon(
                    _notifOpen
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    color:
                        _notifOpen ? const Color(0xFF00E5FF) : textColor,
                    size: 22,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.black : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF44336).withOpacity(0.5),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Text(
                        '$unreadCount',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Real-time Notification Overlay ────────
  Widget _buildNotificationPanel(bool isDark) {
    return Positioned(
      top: 80,
      right: 16,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF13132A).withOpacity(0.96)
                    : Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : AppColors.lightText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _notifOpen = false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 28),
                          ),
                          child: Text(
                            'Dismiss',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF00E5FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.white12),
                  if (_notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No notifications yet.',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white38 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ..._notifications.asMap().entries.map((e) {
                      final n = e.value;
                      return _buildNotifTile(
                        icon: _iconFor(n['icon'] as String),
                        color: Color(n['color'] as int),
                        title: n['title'] as String,
                        body: n['body'] as String,
                        time: n['time'] as String,
                        action: n['action'] as String?,
                        payload: n['payload'],
                        isDark: isDark,
                      )
                          .animate(delay: (e.key * 60).ms)
                          .fadeIn()
                          .slideX(begin: 0.05);
                    }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      )
          .animate()
          .slideY(begin: -0.08, duration: 280.ms, curve: Curves.easeOut)
          .fadeIn(),
    );
  }

  Widget _buildNotifTile({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String time,
    String? action,
    dynamic payload,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _notifOpen = false);
        if (action == 'open_challenge' && payload is String) {
          final challenge = Challenge.allChallenges().firstWhere(
            (c) => c.id == payload,
            orElse: () => Challenge.dummy(),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeScreen(challenge: challenge),
            ),
          );
        } else if (action == 'navigate_tab' && payload is int) {
          widget.onNavigateToTab?.call(payload);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black87,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white38 : Colors.black54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ── XP Section (tappable → Profile tab) ──
  Widget _buildXPSection(UserModel user, bool isDark) {
    final maxXP = user.nextLevelXP;  // uses the real XP curve from UserModel
    final progress = (user.currentXP / maxXP).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => widget.onNavigateToTab?.call(3),
        child: _GlassCard(
          isDark: isDark,
          glowColor: const Color(0xFF00E5FF),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: Color(0xFF00E5FF), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'XP Progress',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : AppColors.lightText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.4)),
                    ),
                    child: Text(
                      '${user.currentXP} / $maxXP XP',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearPercentIndicator(
                lineHeight: 10.0,
                percent: progress,
                padding: EdgeInsets.zero,
                barRadius: const Radius.circular(50),
                backgroundColor: isDark
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05),
                linearGradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF8A38F5)],
                ),
                animation: true,
                animationDuration: 1200,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${user.level}',
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white54 : Colors.black87,
                      fontSize: 11,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% to Level ${user.level + 1}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8A38F5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF8A38F5), size: 10),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────
  Widget _buildStatsRow(UserModel user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _StatChip(
            label: 'Streak',
            value: '${user.streakDays}d',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF6B35),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Coins',
            value: '${user.coins}',
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFFFD700),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Done',
            value: '${user.completedChallengeIds.length}',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF00C853),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Daily Challenges ──────────────────────
  Widget _buildDailyChallenge(
      UserModel user, DatabaseService db, bool isDark) {
    final all = Challenge.allChallenges();
    final uncompleted =
        all.where((c) => !user.completedChallengeIds.contains(c.id)).toList();
    final featured =
        uncompleted.isNotEmpty ? uncompleted.take(2).toList() : all.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with progress pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Challenges',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF00C853).withOpacity(0.4)),
                ),
                child: Text(
                  '${user.completedChallengeIds.length}/${all.length} done',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00C853),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...featured.map((challenge) {
            final isCompleted =
                user.completedChallengeIds.contains(challenge.id);
            final accentColor = isCompleted
                ? const Color(0xFF00C853)
                : const Color(0xFF00E5FF);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GlassCard(
                isDark: isDark,
                glowColor: accentColor,
                borderColor: accentColor.withOpacity(0.5),
                footer: _GradientButton(
                  label: isCompleted ? 'REPLAY CHALLENGE' : 'START CHALLENGE',
                  icon: isCompleted
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded,
                  isCompleted: isCompleted,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallengeScreen(challenge: challenge),
                      ),
                    );
                  },
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.bolt_rounded,
                                color: accentColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isCompleted
                                  ? 'Completed ✓'
                                  : 'Daily Challenge',
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        // Reward / completed badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isCompleted
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFFFD700))
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isCompleted
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFFFD700))
                                  .withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : Icons.bolt_rounded,
                                color: isCompleted
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFFFD700),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted
                                    ? 'XP Earned'
                                    : '+${challenge.xpReward} XP',
                                style: GoogleFonts.poppins(
                                  color: isCompleted
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFFFD700),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Challenge info
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? const LinearGradient(colors: [
                                    Color(0xFF00C853),
                                    Color(0xFF00BFA5)
                                  ])
                                : AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isCompleted
                                        ? const Color(0xFF00C853)
                                        : AppColors.primary)
                                    .withOpacity(0.3),
                                blurRadius: 12,
                              )
                            ],
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.verified_rounded
                                : Icons.code_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Topic: ${challenge.topic}',
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${challenge.questions.length} Questions • ${challenge.difficulty}',
                                style: GoogleFonts.poppins(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          // All-done banner
          if (uncompleted.isEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🎉 You\'ve completed all challenges! New ones coming soon.',
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : AppColors.lightText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuickActionCard(
                title: 'View Challenges',
                subtitle: 'Browse all topics',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFF00E5FF),
                isDark: isDark,
                onTap: () => widget.onNavigateToTab?.call(1),
              ),
              const SizedBox(width: 14),
              _QuickActionCard(
                title: 'Leaderboard',
                subtitle: 'See top players',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFFFD700),
                isDark: isDark,
                onTap: () => widget.onNavigateToTab?.call(2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _QuickActionCard(
                title: 'My Progress',
                subtitle: 'XP & level stats',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF8A38F5),
                isDark: isDark,
                onTap: () => widget.onNavigateToTab?.call(3),
              ),
              const SizedBox(width: 14),
              _QuickActionCard(
                title: 'Achievements',
                subtitle: 'Badges & rewards',
                icon: Icons.military_tech_rounded,
                color: const Color(0xFFFF6B35),
                isDark: isDark,
                onTap: () => widget.onNavigateToTab?.call(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Achievements Preview (live from UserModel) ─
  Widget _buildAchievementsPreview(UserModel user, bool isDark) {
    const allBadges = [
      _Badge('Python\nMaster', Icons.terminal_rounded, Color(0xFF00E5FF),
          'python_master'),
      _Badge('SQL\nQuery', Icons.storage_rounded, Color(0xFF8A38F5),
          'sql_query'),
      _Badge('10 Day\nStreak', Icons.local_fire_department_rounded,
          Color(0xFFFF6B35), 'streak_10'),
      _Badge('Challenge\nAce', Icons.military_tech_rounded, Color(0xFFFFD700),
          'challenge_ace'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigateToTab?.call(3),
                child: Text(
                  'View all →',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: allBadges
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: e.key < allBadges.length - 1 ? 10 : 0),
                        child: _buildBadge(e.value, user, isDark)
                            .animate(delay: (e.key * 80).ms)
                            .scale(begin: const Offset(0.8, 0.8))
                            .fadeIn(),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(_Badge badge, UserModel user, bool isDark) {
    final earned = user.earnedBadgeIds.contains(badge.id);
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: earned
            ? badge.color.withOpacity(0.1)
            : (isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned
              ? badge.color.withOpacity(0.4)
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06)),
          width: 1.3,
        ),
        boxShadow: earned
            ? [BoxShadow(color: badge.color.withOpacity(0.12), blurRadius: 12)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                badge.icon,
                color: earned
                    ? badge.color
                    : (isDark ? Colors.white12 : Colors.black12),
                size: 24,
              ),
              if (!earned)
                Icon(Icons.lock_rounded,
                    color: isDark ? Colors.white24 : Colors.black26, size: 13),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: earned
                  ? badge.color
                  : (isDark ? Colors.white24 : Colors.black26),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (earned)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(Icons.check_circle_rounded,
                  color: badge.color, size: 11),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Helper Widgets
// ─────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? glowColor;
  final Color? borderColor;
  final Widget? footer;

  const _GlassCard({
    required this.child,
    required this.isDark,
    this.glowColor,
    this.borderColor,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppColors.primary;
    final border = borderColor ?? glow.withOpacity(0.3);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: glow.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 1,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: child,
              ),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isCompleted;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isCompleted
        ? const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
          )
        : AppColors.primaryGradient;
    final shadowColor = isCompleted
        ? const Color(0xFF00C853)
        : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white54 : Colors.black87,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: isDark
                      ? color.withOpacity(0.07)
                      : color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withOpacity(0.35),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white : AppColors.lightText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              color: color.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────

class _Badge {
  final String label;
  final IconData icon;
  final Color color;
  final String id;

  const _Badge(this.label, this.icon, this.color, this.id);
}
