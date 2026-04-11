import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../models/challenge_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'challenge_screen.dart';

// ─────────────────────────────────────────────
//  ChallengesPage
//  Full challenge catalogue with search, filters,
//  difficulty badges, and navigation to ChallengeScreen.
// ─────────────────────────────────────────────
class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'Easy', 'Medium', 'Hard'];

  Map<String, DateTime> _lastRunTimes = {};
  /// challengeId -> true means user got every question right at least once
  Map<String, bool> _perfectFlags = {};

  @override
  void initState() {
    super.initState();
    _loadLocalFlags();
  }

  Future<void> _loadLocalFlags() async {
    final uid = context.read<UserModel>().uid;
    final prefs = await SharedPreferences.getInstance();
    final runMap = <String, DateTime>{};
    final perfectMap = <String, bool>{};
    for (final c in Challenge.allChallenges()) {
      final runStr = prefs.getString('ch_last_run_${uid}_${c.id}');
      if (runStr != null) runMap[c.id] = DateTime.parse(runStr);
      perfectMap[c.id] = prefs.getBool('ch_perfect_${uid}_${c.id}') ?? false;
    }
    if (mounted) {
      setState(() {
        _lastRunTimes = runMap;
        _perfectFlags = perfectMap;
      });
    }
  }

  // Category metadata ─────────────────────────
  static const Map<String, _CategoryMeta> _categories = {
    'Python Challenges': _CategoryMeta(
      icon: Icons.terminal_rounded,
      color: Color(0xFF4B8BBE),
      tag: 'py',
    ),
    'Java Challenges': _CategoryMeta(
      icon: Icons.coffee_rounded,
      color: Color(0xFFED8B00),
      tag: 'java',
    ),
    'Database SQL': _CategoryMeta(
      icon: Icons.storage_rounded,
      color: Color(0xFF8A38F5),
      tag: 'sql',
    ),
    'Networking Quiz': _CategoryMeta(
      icon: Icons.wifi_rounded,
      color: Color(0xFF00E5FF),
      tag: 'net',
    ),
    'JavaScript': _CategoryMeta(
      icon: Icons.javascript_rounded,
      color: Color(0xFFF7DF1E),
      tag: 'js',
    ),
    'Git & Version Control': _CategoryMeta(
      icon: Icons.account_tree_rounded,
      color: Color(0xFFF1502F),
      tag: 'git',
    ),
    'Linux OS': _CategoryMeta(
      icon: Icons.terminal_rounded,
      color: Color(0xFFFCC624),
      tag: 'linux',
    ),
    'Web Development': _CategoryMeta(
      icon: Icons.html_rounded,
      color: Color(0xFFE34F26),
      tag: 'web',
    ),
    'C++ Programming': _CategoryMeta(
      icon: Icons.data_object_rounded,
      color: Color(0xFF00599C),
      tag: 'cpp',
    ),
    'Cybersecurity': _CategoryMeta(
      icon: Icons.security_rounded,
      color: Color(0xFF00C853),
      tag: 'sec',
    ),
  };

  List<Challenge> get _filtered {
    return Challenge.allChallenges().where((c) {
      final matchesDiff =
          _selectedFilter == 'All' || c.difficulty == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.topic.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDiff && matchesSearch;
    }).toList();
  }

  Map<String, List<Challenge>> get _groupedChallenges {
    final map = <String, List<Challenge>>{};
    for (final cat in _categories.keys) {
      final tag = _categories[cat]!.tag;
      final list = _filtered.where((c) => c.id.startsWith(tag)).toList();
      if (list.isNotEmpty) map[cat] = list;
    }
    return map;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = _groupedChallenges;

    return GlassScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Fixed header ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 16),
                  _buildSearchBar(isDark),
                  const SizedBox(height: 16),
                  _buildFilterRow(isDark),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            // ── Scrollable content ────────────
            Expanded(
              child: grouped.isEmpty
                  ? _buildEmptyState(isDark)
                  : Consumer<UserModel>(
                      builder: (context, user, _) => ListView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                        children: grouped.entries
                            .map((e) => _buildCategory(
                                e.key,
                                _categories[e.key]!,
                                e.value,
                                isDark,
                                user.completedChallengeIds))
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.lightText;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.3), blurRadius: 12)
            ],
          ),
          child: const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Consumer<UserModel>(
          builder: (context, user, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenges',
                style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                '${user.completedChallengeIds.length}/${Challenge.allChallenges().length} completed',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF00E5FF), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05);
  }

  // ── Search bar ────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: GoogleFonts.poppins(
          color: isDark ? Colors.white : AppColors.lightText, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search challenges...',
        hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.white38 : Colors.black87, fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded,
            color: const Color(0xFF00E5FF), size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.black87, size: 18),
              )
            : null,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF00E5FF), width: 1.3),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Filter chips ──────────────────────────
  Widget _buildFilterRow(bool isDark) {
    return Row(
      children: _filters.map((f) => _filterChip(f, isDark)).toList(),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _filterChip(String label, bool isDark) {
    final isActive = _selectedFilter == label;
    Color chipColor;
    switch (label) {
      case 'Easy':
        chipColor = const Color(0xFF43A047);
        break;
      case 'Medium':
        chipColor = const Color(0xFFFFC331);
        break;
      case 'Hard':
        chipColor = const Color(0xFFF44336);
        break;
      default:
        chipColor = const Color(0xFF00E5FF);
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? chipColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? chipColor
                  : (isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08)),
              width: 1.3,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: chipColor.withOpacity(0.25), blurRadius: 10)
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isActive
                  ? chipColor
                  : (isDark ? Colors.white54 : Colors.black87),
              fontSize: 11,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Category section ──────────────────────
  Widget _buildCategory(String title, _CategoryMeta meta,
      List<Challenge> challenges, bool isDark, List<String> completedIds) {
    final completedCount =
        challenges.where((c) => completedIds.contains(c.id)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: meta.color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : AppColors.lightText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completedCount/${challenges.length}',
                style: GoogleFonts.poppins(
                    color: meta.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ).animate().fadeIn(),
        const SizedBox(height: 12),
        ...challenges.asMap().entries.map(
              (e) => _buildChallengeCard(
                  e.value, meta, isDark, e.key, completedIds),
            ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Challenge card ────────────────────────
  Widget _buildChallengeCard(Challenge challenge, _CategoryMeta meta,
      bool isDark, int index, List<String> completedIds) {
    final isCompleted = completedIds.contains(challenge.id);
    final isPerfect = _perfectFlags[challenge.id] ?? false;

    // ── Coin cost for retaking a completed-but-imperfect challenge ──────
    int retryCoinCost;
    switch (challenge.difficulty) {
      case 'Hard':
        retryCoinCost = 20;
        break;
      case 'Medium':
        retryCoinCost = 10;
        break;
      case 'Easy':
      default:
        retryCoinCost = 5;
    }

    Color diffColor;
    IconData diffIcon;
    switch (challenge.difficulty) {
      case 'Easy':
        diffColor = const Color(0xFF43A047);
        diffIcon = Icons.signal_cellular_alt_1_bar_rounded;
        break;
      case 'Medium':
        diffColor = const Color(0xFFFFC331);
        diffIcon = Icons.signal_cellular_alt_2_bar_rounded;
        break;
      default:
        diffColor = const Color(0xFFF44336);
        diffIcon = Icons.signal_cellular_alt_rounded;
    }

    return GestureDetector(
      onTap: () async {
        if (!isCompleted) {
          // ── Normal first attempt ─────────────────────────────────────
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeScreen(challenge: challenge),
            ),
          );
          _loadLocalFlags();
        } else if (isPerfect) {
          // ── Free review: perfect score already recorded ───────────────
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeScreen(challenge: challenge),
            ),
          );
          _loadLocalFlags();
        } else {
          // ── Coin buy-in required: completed but had wrong answers ──────
          final user = context.read<UserModel>();
          final confirmed = await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _RetakeBuyInSheet(
              challenge: challenge,
              coinCost: retryCoinCost,
              userCoins: user.coins,
              isDark: isDark,
            ),
          );
          if (confirmed == true && context.mounted) {
            final db = context.read<DatabaseService>();
            final spent = await db.spendCoins(userModel: user, cost: retryCoinCost);
            if (spent && context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChallengeScreen(challenge: challenge),
                ),
              );
              _loadLocalFlags();
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Not enough coins to retake!'),
                  backgroundColor: const Color(0xFFFF3D71),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              );
            }
          }
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? const Color(0xFF00C853).withOpacity(0.1)
                    : meta.color.withOpacity(0.06),
                blurRadius: 16,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(isCompleted ? 0.06 : 0.04)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF00C853).withOpacity(0.5)
                        : meta.color.withOpacity(0.3),
                    width: 1.3,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon with completion overlay
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF00C853).withOpacity(0.12)
                                : meta.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : meta.icon,
                            color: isCompleted
                                ? const Color(0xFF00C853)
                                : meta.color,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  challenge.title,
                                  style: GoogleFonts.poppins(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            challenge.topic,
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black87,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Difficulty badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: diffColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: diffColor.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(diffIcon, color: diffColor, size: 11),
                                    const SizedBox(width: 3),
                                    Text(
                                      challenge.difficulty,
                                      style: GoogleFonts.poppins(
                                        color: diffColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Questions count
                              Text(
                                '${challenge.questions.length} Qs',
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black87,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status column (right side)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Top chip: XP for uncompleted / Perfect for perfect / Coin cost for imperfect
                        if (!isCompleted)
                          _statusChip(
                            label: '+${challenge.xpReward} XP',
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFFFFD700),
                          )
                        else if (isPerfect)
                          _statusChip(
                            label: '🎯 Perfect',
                            color: const Color(0xFF00C853),
                          )
                        else
                          _statusChip(
                            label: '🪙 $retryCoinCost coins',
                            color: const Color(0xFFFFBD2E),
                          ),
                        const SizedBox(height: 8),
                        // Bottom arrow / replay icon
                        Icon(
                          isCompleted
                              ? Icons.replay_rounded
                              : Icons.arrow_forward_ios_rounded,
                          color: isCompleted
                              ? (isPerfect
                                  ? const Color(0xFF00C853).withOpacity(0.7)
                                  : const Color(0xFFFFBD2E).withOpacity(0.7))
                              : meta.color.withOpacity(0.6),
                          size: 14,
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
    )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05);
  }

  // Small reusable status chip
  Widget _statusChip({
    required String label,
    IconData? icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              color: isDark ? Colors.white24 : Colors.black26, size: 64),
          const SizedBox(height: 16),
          Text(
            'No challenges found',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white54 : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different filter or search term.',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white38 : Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

// ── Category metadata ─────────────────────────
class _CategoryMeta {
  final IconData icon;
  final Color color;
  final String tag;

  const _CategoryMeta(
      {required this.icon, required this.color, required this.tag});
}

// ─────────────────────────────────────────────
//  _RetakeBuyInSheet
//  Modal bottom sheet shown when a user taps a
//  completed-but-imperfect challenge, asking them
//  to spend coins for a retake.
// ─────────────────────────────────────────────
class _RetakeBuyInSheet extends StatelessWidget {
  final Challenge challenge;
  final int coinCost;
  final int userCoins;
  final bool isDark;

  const _RetakeBuyInSheet({
    required this.challenge,
    required this.coinCost,
    required this.userCoins,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAfford = userCoins >= coinCost;
    final Color accentColor =
        canAfford ? const Color(0xFFFFBD2E) : const Color(0xFFFF3D71);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF13132A).withOpacity(0.98)
            : Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border:
                  Border.all(color: accentColor.withOpacity(0.5), width: 2),
            ),
            child: Center(
              child: Text(
                canAfford ? '🔄' : '💸',
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            canAfford ? 'Retake Challenge?' : 'Not Enough Coins',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            challenge.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          // Cost & balance row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip('Cost', '🪙 $coinCost', accentColor),
              const SizedBox(width: 12),
              _infoChip(
                  'Your Balance', '🪙 $userCoins',
                  canAfford
                      ? const Color(0xFF00C853)
                      : const Color(0xFFFF3D71)),
            ],
          ),
          const SizedBox(height: 8),
          if (!canAfford) ...[
            const SizedBox(height: 4),
            Text(
              'You need ${coinCost - userCoins} more coins to retry this challenge.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFFFF3D71),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  canAfford ? () => Navigator.of(context).pop(true) : null,
              icon: Icon(
                  canAfford ? Icons.play_arrow_rounded : Icons.block_rounded),
              label: Text(
                canAfford
                    ? 'Spend $coinCost Coins & Retake'
                    : 'Insufficient Coins',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford
                    ? const Color(0xFFFFBD2E)
                    : Colors.grey.withOpacity(0.3),
                foregroundColor:
                    canAfford ? Colors.black87 : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.white54 : Colors.black54,
                side: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
