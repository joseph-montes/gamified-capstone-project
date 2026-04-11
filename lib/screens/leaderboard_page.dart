import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../models/user_model.dart';
import '../theme/app_theme.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(isDark)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('currentXP', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No Heroes Found.",
                        style: GoogleFonts.cambo(
                            color: isDark ? Colors.white54 : Colors.black87,
                            fontSize: 18),
                      ),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final isCurrentUser = users[index].id == currentUser.uid;

                      return _buildLeaderboardCard(
                        rank: index + 1,
                        name: userData['fullName'] ?? 'Unknown Hero',
                        studentId: userData['studentId'] ?? '',
                        photoUrl: userData['photoUrl'] ?? '',
                        xp: userData['currentXP'] ?? 0,
                        level: userData['level'] ?? 1,
                        isCurrentUser: isCurrentUser,
                        isDark: isDark,
                      )
                          .animate()
                          .fadeIn(delay: (index * 100).ms)
                          .slideX(begin: 0.1);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Center(
            child:
                Icon(Icons.sports_esports, size: 40, color: Color(0xFF00E5FF)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'CodeQuest',
          style: GoogleFonts.kumarOne(
              color: isDark ? Colors.white : AppColors.lightText, fontSize: 28),
        ),
        Text(
          'LEADERBOARD',
          style: GoogleFonts.inter(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required String name,
    required String studentId,
    required String photoUrl,
    required int xp,
    required int level,
    required bool isCurrentUser,
    required bool isDark,
  }) {
    Color borderColor;
    Color glowColor;
    double glowRadius;

    if (isCurrentUser) {
      borderColor = const Color(0xFF00E5FF);
      glowColor = const Color(0xFF00E5FF).withOpacity(0.4);
      glowRadius = 25;
    } else if (rank == 1) {
      borderColor = const Color(0xFFFFD700);
      glowColor = const Color(0xFFFFD700).withOpacity(0.2);
      glowRadius = 20;
    } else if (rank == 2) {
      borderColor = const Color(0xFFC0C0C0);
      glowColor = const Color(0xFFC0C0C0).withOpacity(0.15);
      glowRadius = 15;
    } else if (rank == 3) {
      borderColor = const Color(0xFFCD7F32);
      glowColor = const Color(0xFFCD7F32).withOpacity(0.15);
      glowRadius = 15;
    } else {
      borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1);
      glowColor = Colors.transparent;
      glowRadius = 0;
    }

    final double progress = (xp % 1000) / 1000.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (glowRadius > 0)
            BoxShadow(
              color: glowColor,
              blurRadius: glowRadius,
              spreadRadius: 1,
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: borderColor, width: isCurrentUser ? 2 : 1.5),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: rank <= 3
                          ? borderColor
                          : (isDark ? Colors.white70 : AppColors.lightText.withOpacity(0.7)),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  backgroundImage: photoUrl.isNotEmpty
                      ? (photoUrl.startsWith('data:image/')
                          ? MemoryImage(base64Decode(photoUrl.split(',').last))
                          : NetworkImage(photoUrl)) as ImageProvider
                      : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  child: rank == 1
                      ? const Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.star,
                              color: Color(0xFFFFD700), size: 16),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : AppColors.lightText,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'YOU',
                                style: GoogleFonts.cambo(
                                    color: const Color(0xFF00E5FF),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]
                        ],
                      ),
                      if (studentId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'ID: $studentId',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white54 : AppColors.lightText.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: borderColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: borderColor.withOpacity(0.5),
                                      blurRadius: 4)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatXP(xp)} XP',
                      style: GoogleFonts.cambo(
                          color: isDark ? Colors.white : AppColors.lightText,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        'Lv.$level',
                        style:
                            GoogleFonts.cambo(color: borderColor, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatXP(int xp) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return xp.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }
}
