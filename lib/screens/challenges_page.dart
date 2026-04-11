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

  @override
  void initState() {
    super.initState();
    _loadRunTimes();
  }

  Future<void> _loadRunTimes() async {
    final uid = context.read<UserModel>().uid;
    final prefs = await SharedPreferences.getInstance();
    final map = <String, DateTime>{};
    for (final c in Challenge.allChallenges()) {
      final str = prefs.getString('ch_last_run_${uid}_${c.id}');
      if (str != null) map[c.id] = DateTime.parse(str);
    }
    if (mounted) setState(() => _lastRunTimes = map);
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
    final lastRun = _lastRunTimes[challenge.id];
    final canReplay = isCompleted &&
        (lastRun == null || DateTime.now().difference(lastRun).inHours >= 24);

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
        if (isCompleted && !canReplay) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You can only retake this challenge after 24 hours.'),
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChallengeScreen(challenge: challenge),
          ),
        );
        _loadRunTimes();
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
                    // XP + Arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF00C853).withOpacity(0.08)
                                : const Color(0xFFFFD700).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF00C853).withOpacity(0.3)
                                  : const Color(0xFFFFD700).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Only show XP icon (bolt) for uncompleted; no check icon for completed
                              if (!isCompleted)
                                Icon(
                                  Icons.bolt_rounded,
                                  color: const Color(0xFFFFD700),
                                  size: 13,
                                ),
                              if (!isCompleted) const SizedBox(width: 2),
                              Text(
                                isCompleted
                                    ? 'Earned'
                                    : '+${challenge.xpReward}',
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
                        const SizedBox(height: 8),
                        // Bottom-right: show 24h countdown when locked, replay when available
                        if (isCompleted && !canReplay && lastRun != null)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(Icons.lock_clock_rounded,
                                  color: Colors.grey.withOpacity(0.6), size: 14),
                              const SizedBox(height: 2),
                              Text(
                                '${(24 - DateTime.now().difference(lastRun!).inHours).clamp(1, 24)}h',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey, fontSize: 9),
                              ),
                            ],
                          )
                        else
                          Icon(
                            isCompleted
                                ? Icons.replay_rounded
                                : Icons.arrow_forward_ios_rounded,
                            color: isCompleted
                                ? const Color(0xFF00C853).withOpacity(0.6)
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
