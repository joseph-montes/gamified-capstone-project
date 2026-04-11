import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class QuizScreen extends StatefulWidget {
  final String challengeTitle;
  final int xpReward;

  const QuizScreen({
    super.key,
    required this.challengeTitle,
    required this.xpReward,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // For demonstration, these are static. In the future, fetch these from Firestore too!
  final String question = "What is the correct syntax to output 'Hello World' in Python?";
  final List<String> options = [
    "echo('Hello World')",
    "print('Hello World')",
    "console.log('Hello World')",
    "System.out.println('Hello World')"
  ];
  final int correctAnswerIndex = 1;

  int? _selectedIndex;
  bool _isAnswered = false;
  bool _isCorrect = false;

  void _submitAnswer() async {
    if (_selectedIndex == null) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = _selectedIndex == correctAnswerIndex;
    });

    if (_isCorrect) {
      final user = context.read<UserModel>();
      final db = context.read<DatabaseService>();
      
      // ONLY award XP after validation
      await db.awardXP(userModel: user, xpAmount: widget.xpReward);
      
      if (mounted) {
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 4,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: Color(0xFF00E5FF), size: 60)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                'Challenge Complete!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+${widget.xpReward} XP Earned',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Return to Dashboard',
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : AppColors.lightText),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Text(
                widget.challengeTitle,
                style: GoogleFonts.inter(
                  color: const Color(0xFF00E5FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              Text(
                question,
                style: GoogleFonts.cambo(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 22,
                  height: 1.4,
                ),
              ).animate().slideX(begin: 0.1).fadeIn(),
              const SizedBox(height: 40),
              ...List.generate(options.length, (index) {
                final isSelected = _selectedIndex == index;
                Color borderColor = isDark ? Colors.white24 : Colors.black26;
                Color bgColor = Colors.transparent;

                if (_isAnswered) {
                  if (index == correctAnswerIndex) {
                    borderColor = const Color(0xFF00E676); // Green for correct
                    bgColor = const Color(0xFF00E676).withOpacity(0.1);
                  } else if (isSelected && index != correctAnswerIndex) {
                    borderColor = const Color(0xFFFF3D71); // Red for wrong
                    bgColor = const Color(0xFFFF3D71).withOpacity(0.1);
                  }
                } else if (isSelected) {
                  borderColor = const Color(0xFF00E5FF);
                  bgColor = const Color(0xFF00E5FF).withOpacity(0.1);
                }

                return GestureDetector(
                  onTap: _isAnswered ? null : () => setState(() => _selectedIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            options[index],
                            // CHANGED: Replaced the non-existent font with firaCode
                            style: GoogleFonts.firaCode(
                              color: isDark ? Colors.white : AppColors.lightText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_isAnswered && index == correctAnswerIndex)
                          const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                        if (_isAnswered && isSelected && index != correctAnswerIndex)
                          const Icon(Icons.cancel, color: Color(0xFFFF3D71)),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.2, delay: (100 * index).ms).fadeIn();
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: _isAnswered ? (_isCorrect ? 'Finished' : 'Try Again Later') : 'Submit Answer',
                  onPressed: _selectedIndex == null || _isAnswered ? null : _submitAnswer,
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
