import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'settings_page.dart';

// ─────────────────────────────────────────────
//  ProfilePage
// ─────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  void _showBadgeToast(List<String> badgeIds) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.military_tech_rounded,
                color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🎉 ${badgeIds.length} achievement${badgeIds.length > 1 ? "s" : ""} unlocked!',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A3E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark, user),
              const SizedBox(height: 20),
              _buildUserCard(context, user, isDark)
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 16),
              _buildStatsGrid(user, isDark)
                  .animate()
                  .fadeIn(delay: 180.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 16),
              _buildXPCard(user, isDark)
                  .animate()
                  .fadeIn(delay: 240.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 16),
              _buildAchievements(user, isDark)
                  .animate()
                  .fadeIn(delay: 280.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 16),
              _buildActionButtons(context, isDark)
                  .animate()
                  .fadeIn(delay: 400.ms),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark, UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : AppColors.lightText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_rounded, color: AppColors.primary, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  // ── User card with photo upload ────────────
  Widget _buildUserCard(BuildContext context, UserModel user, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.lightText;
    return _GlassCard(
      isDark: isDark,
      glowColor: AppColors.primary,
      child: Row(
        children: [
          // Avatar (Display Only)
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 20,
                )
              ],
            ),
            child: ClipOval(
              child: user.photoUrl.isNotEmpty
                  ? (user.photoUrl.startsWith('data:image/')
                      ? Image.memory(
                          base64Decode(user.photoUrl.split(',').last),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initials(user, isDark),
                        )
                      : Image.network(
                          user.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initials(user, isDark),
                        ))
                  : _defaultAvatar(user),
            ),
          ),
          const SizedBox(width: 18),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Guest Hero' : user.fullName,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black87,
                    fontSize: 12,
                  ),
                ),
                if (user.motto.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${user.motto}"',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00E5FF),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _InfoPill(
                      label: user.studentId.isEmpty ? 'No ID' : user.studentId,
                      icon: Icons.badge_rounded,
                      color: const Color(0xFF8A38F5),
                    ),
                    const SizedBox(width: 8),
                    _InfoPill(
                      label: user.yearLevel.isEmpty
                          ? 'No Year'
                          : user.yearLevel,
                      icon: Icons.school_rounded,
                      color: const Color(0xFF00E5FF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shows the default avatar asset for new users with no photo
  Widget _defaultAvatar(UserModel user) {
    return Image.asset(
      'assets/images/default_avatar.png',
      fit: BoxFit.cover,
    );
  }

  Widget _initials(UserModel user, bool isDark) {
    return Center(
      child: Text(
        user.displayInitials,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ── Stats grid ────────────────────────────
  Widget _buildStatsGrid(UserModel user, bool isDark) {
    final stats = [
      _Stat(
          label: 'Level',
          value: '${user.level}',
          icon: Icons.military_tech_rounded,
          color: const Color(0xFF8A38F5)),
      _Stat(
          label: 'XP',
          value: '${user.currentXP}',
          icon: Icons.bolt_rounded,
          color: const Color(0xFF00E5FF)),
      _Stat(
          label: 'Streak',
          value: '${user.streakDays}d',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B35)),
      _Stat(
          label: 'Coins',
          value: '${user.coins}',
          icon: Icons.monetization_on_rounded,
          color: const Color(0xFFFFD700)),
      _Stat(
          label: 'Quizzes',
          value: '${user.totalQuizzesCompleted}',
          icon: Icons.quiz_rounded,
          color: const Color(0xFF43A047)),
      _Stat(
          label: 'Lessons',
          value: '${user.totalLessonsCompleted}',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFFFF6B35)),
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: stats.asMap().entries.map((e) {
        return _buildStatTile(e.value, isDark)
            .animate(delay: (e.key * 40).ms)
            .scale(begin: const Offset(0.85, 0.85))
            .fadeIn();
      }).toList(),
    );
  }

  Widget _buildStatTile(_Stat stat, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stat.color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: stat.color.withOpacity(0.06), blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: stat.color, size: 22),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            stat.label,
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white38 : Colors.black87,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── XP / Progress card ────────────────────
  Widget _buildXPCard(UserModel user, bool isDark) {
    final maxXP = user.nextLevelXP;
    final progress = (user.currentXP / maxXP).clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(0);

    return _GlassCard(
      isDark: isDark,
      glowColor: const Color(0xFF8A38F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP Progress',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$pct% to Level ${user.level + 1}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF8A38F5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: progress,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(50),
            backgroundColor:
                isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
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
                    color: isDark ? Colors.white38 : Colors.black87,
                    fontSize: 10),
              ),
              Text(
                '${user.currentXP} / $maxXP XP',
                style: GoogleFonts.poppins(
                    color: isDark ? Colors.white38 : Colors.black87,
                    fontSize: 10),
              ),
              Text(
                'Level ${user.level + 1}',
                style: GoogleFonts.poppins(
                    color: isDark ? Colors.white38 : Colors.black87,
                    fontSize: 10),
              ),
            ],
          ),
          if (user.rankTitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 6),
                Text(
                  user.rankTitle,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Achievements (auto-awards on condition) ─
  Widget _buildAchievements(UserModel user, bool isDark) {
    const allBadges = [
      _BadgeDef(
          id: 'python_master',
          label: 'Python\nMaster',
          icon: Icons.terminal_rounded,
          color: Color(0xFF4B8BBE),
          hint: '5 quizzes completed'),
      _BadgeDef(
          id: 'sql_query',
          label: 'SQL\nQuery',
          icon: Icons.storage_rounded,
          color: Color(0xFF8A38F5),
          hint: '3 quizzes completed'),
      _BadgeDef(
          id: 'streak_10',
          label: '10-Day\nStreak',
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFFF6B35),
          hint: '10-day login streak'),
      _BadgeDef(
          id: 'challenge_ace',
          label: 'Challenge\nAce',
          icon: Icons.military_tech_rounded,
          color: Color(0xFFFFD700),
          hint: '10 quizzes completed'),
      _BadgeDef(
          id: 'data_analysis',
          label: 'Data\nAnalysis',
          icon: Icons.analytics_rounded,
          color: Color(0xFF00E5FF),
          hint: '500 XP earned'),
      _BadgeDef(
          id: 'api_explorer',
          label: 'API\nExplorer',
          icon: Icons.api_rounded,
          color: Color(0xFF43A047),
          hint: 'Reach Level 5'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${user.earnedBadgeIds.length} of ${allBadges.length} badges earned',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white38 : Colors.black87,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: allBadges.asMap().entries.map((e) {
            final badge = e.value;
            final earned = user.earnedBadgeIds.contains(badge.id);
            return GestureDetector(
              onTap: () => _showBadgeDetail(badge, earned, isDark),
              child: _buildBadgeTile(badge, earned, isDark)
                  .animate(delay: (e.key * 60).ms)
                  .scale(begin: const Offset(0.8, 0.8))
                  .fadeIn(),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showBadgeDetail(_BadgeDef badge, bool earned, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF13132A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badge.icon,
              color: earned ? badge.color : Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              badge.label.replaceAll('\n', ' '),
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : AppColors.lightText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              earned ? '✅ Badge Earned!' : '🔒 Locked',
              style: GoogleFonts.poppins(
                color: earned ? badge.color : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Requirement: ${badge.hint}',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: badge.color)),
          )
        ],
      ),
    );
  }

  Widget _buildBadgeTile(_BadgeDef badge, bool earned, bool isDark) {
    return Container(
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
          width: 1.2,
        ),
        boxShadow: earned
            ? [BoxShadow(color: badge.color.withOpacity(0.15), blurRadius: 12)]
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
                    : (isDark
                        ? Colors.white12
                        : Colors.black.withOpacity(0.08)),
                size: 30,
              ),
              if (!earned)
                Icon(Icons.lock_rounded,
                    color: isDark ? Colors.white24 : Colors.black26, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: earned
                  ? badge.color
                  : (isDark ? Colors.white24 : Colors.black26),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (earned)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.check_circle_rounded,
                  color: badge.color, size: 12),
            ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────
  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _OutlineButton(
            label: 'EDIT PROFILE',
            icon: Icons.edit_rounded,
            onTap: () =>
                _showEditProfileSheet(context, context.read<UserModel>()),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _DangerButton(
            label: 'LOGOUT',
            icon: Icons.logout_rounded,
            onTap: () => _confirmLogout(context),
          ),
        ),
      ],
    );
  }

  void _showEditProfileSheet(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final idCtrl = TextEditingController(text: user.studentId);
    final mottoCtrl = TextEditingController(text: user.motto);
    String? selectedYear = user.yearLevel.isEmpty ? null : user.yearLevel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();

    Uint8List? pendingPhotoBytes;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D0D1F).withOpacity(0.97)
                      : Colors.white.withOpacity(0.98),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Form(
                  key: formKey,
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
                            color: isDark
                                ? Colors.white24
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white : AppColors.lightText,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded,
                                color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ── Avatar selector in sheet ──
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                                border: Border.all(color: AppColors.primary, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: pendingPhotoBytes != null
                                    ? Image.memory(
                                        pendingPhotoBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : user.photoUrl.isNotEmpty
                                        ? (user.photoUrl.startsWith('data:image/')
                                            ? Image.memory(
                                                base64Decode(user.photoUrl.split(',').last),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _initials(user, isDark),
                                              )
                                            : Image.network(
                                                user.photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _initials(user, isDark),
                                              ))
                                        : _defaultAvatar(user),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  if (isSaving) return;
                                  if (!user.canChangePhoto) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('You can change your photo again in ${user.daysUntilPhotoChange} days.',
                                            style: GoogleFonts.poppins(color: Colors.white)),
                                        backgroundColor: const Color(0xFFFF3D71),
                                      ),
                                    );
                                    return;
                                  }
                                  final picker = ImagePicker();
                                  final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                                  if (picked != null) {
                                    final bytes = await picked.readAsBytes();
                                    setModalState(() {
                                      pendingPhotoBytes = bytes;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: isDark ? const Color(0xFF0D0D1F) : Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SheetField(
                        controller: nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _SheetField(
                        controller: idCtrl,
                        label: 'Student ID',
                        icon: Icons.badge_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(7),
                        ],
                        validator: (value) {
                          if (value == null || value.length != 7) {
                            return 'ID must be exactly 7 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        dropdownColor: isDark
                            ? const Color(0xFF1A1A2E)
                            : Colors.white,
                        style: GoogleFonts.poppins(
                            color: isDark
                                ? Colors.white
                                : AppColors.lightText,
                            fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Year Level',
                          hintStyle: GoogleFonts.poppins(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black87,
                              fontSize: 13),
                          prefixIcon: Icon(Icons.school_rounded,
                              color: AppColors.primary.withOpacity(0.6),
                              size: 20),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.06)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                        items: [
                          '1st Year',
                          '2nd Year',
                          '3rd Year',
                          '4th Year'
                        ]
                            .map((y) => DropdownMenuItem(
                                value: y, child: Text(y)))
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => selectedYear = v),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: mottoCtrl,
                        style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : AppColors.lightText,
                            fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Catchphrase / Bio',
                          filled: true,
                          fillColor:
                              isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.06)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              setModalState(() => isSaving = true);
                              try {
                                user.fullName = nameCtrl.text.trim();
                                user.studentId = idCtrl.text.trim();
                                user.motto = mottoCtrl.text.trim();
                                user.yearLevel = selectedYear ?? user.yearLevel;
                                user.notifyListeners();
                                
                                final db = context.read<DatabaseService>();
                                
                                if (pendingPhotoBytes != null) {
                                  await db.uploadUserPhoto(userModel: user, imageBytes: pendingPhotoBytes!);
                                }
                                
                                await db.updateUserProfile(userModel: user);
                                
                                // Check badges after profile update
                                final unlocked = await db.checkAndUnlockBadges(userModel: user);
                                if (context.mounted && unlocked.isNotEmpty) {
                                  _showBadgeToast(unlocked);
                                }
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Update failed: $e', style: GoogleFonts.poppins(color: Colors.white)),
                                    backgroundColor: const Color(0xFFFF3D71),
                                  ));
                                }
                                setModalState(() => isSaving = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledForegroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: isSaving 
                                  ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                                  : AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'SAVE CHANGES',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                            ),
                          ),
                        ),
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

  // ── Logout confirm dialog ─────────────────
  void _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF13132A) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leaving so soon?',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : AppColors.lightText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Your progress is saved. You can continue your quest next time!',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white54 : Colors.black87,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<DatabaseService>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3D71),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('LOG OUT',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color glowColor;

  const _GlassCard(
      {required this.child,
      required this.isDark,
      required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: glowColor.withOpacity(0.25), width: 1.3),
            boxShadow: [
              BoxShadow(
                  color: glowColor.withOpacity(0.07),
                  blurRadius: 20,
                  spreadRadius: 1)
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoPill(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _SheetField(
      {required this.controller,
      required this.label,
      required this.icon,
      required this.isDark,
      this.keyboardType,
      this.inputFormatters,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.poppins(
          color: isDark ? Colors.white : AppColors.lightText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            color: isDark ? Colors.white54 : Colors.black87, fontSize: 12),
        prefixIcon: Icon(icon,
            color: AppColors.primary.withOpacity(0.6), size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.3),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isDark ? Colors.white70 : AppColors.lightText,
                size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : AppColors.lightText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DangerButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3D71).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFFF3D71).withOpacity(0.6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF3D71), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF3D71),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data holders ──────────────────────────────
class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

class _BadgeDef {
  final String id, label, hint;
  final IconData icon;
  final Color color;
  const _BadgeDef(
      {required this.id,
      required this.label,
      required this.icon,
      required this.color,
      required this.hint});
}
