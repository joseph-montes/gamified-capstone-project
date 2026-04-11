import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import '../models/challenge_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

// ─────────────────────────────────────────────
//  ChallengeScreen
//  The core gameplay loop for a single Challenge.
// ─────────────────────────────────────────────
class ChallengeScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeScreen({super.key, required this.challenge});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────
  int _currentIndex = 0;
  int _score = 0;

  /// Index the user tapped; null means no answer yet.
  int? _selectedAnswer;

  /// Whether an answer has been confirmed for the current question.
  bool _answered = false;

  late final AnimationController _fadeController;
  late final List<Question> _shuffledQuestions;

  // ── Helpers ───────────────────────────────
  Question get _current => _shuffledQuestions[_currentIndex];
  int get _total => _shuffledQuestions.length;
  double get _progress => (_currentIndex + 1) / _total;

  Timer? _questionTimer;
  int _timeRemaining = 0;
  int _maxTime = 0;

  @override
  void initState() {
    super.initState();
    _shuffledQuestions = widget.challenge.questions.map((q) {
      if (q.options.isEmpty) return q; // Guard against empty options
      final originalCorrectText = q.options[q.correctAnswerIndex];
      // Create a copy of the options and shuffle them randomly
      final newOptions = List<String>.from(q.options)..shuffle();
      // Find the new index of the originally correct answer
      final newCorrectIndex = newOptions.indexOf(originalCorrectText);
      return Question(
        questionText: q.questionText,
        codeSnippet: q.codeSnippet,
        options: newOptions,
        correctAnswerIndex: newCorrectIndex,
      );
    }).toList();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    // Start initial timer in next frame so we have access to context.read
    Future.microtask(() => _startTimerForQuestion());
  }

  void _startTimerForQuestion() {
    int baseTime = 15;
    final diff = widget.challenge.difficulty.toLowerCase();
    if (diff == 'easy') baseTime = 20;
    else if (diff == 'medium') baseTime = 15;
    else if (diff == 'hard') baseTime = 10;
    
    // Decrease time based on how 'advanced' the player is (level up = faster time limits)
    if (mounted) {
      final user = context.read<UserModel>();
      int deduction = (user.level / 5).floor(); // i.e., -1s every 5 levels
      int finalTime = baseTime - deduction;
      if (finalTime < 5) finalTime = 5; // Absolute minimum of 5s per question
      _maxTime = finalTime;
    } else {
      _maxTime = baseTime;
    }

    _timeRemaining = _maxTime;

    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          timer.cancel();
          _handleTimeOut();
        }
      });
    });
  }

  void _handleTimeOut() {
    if (_answered) return;
    setState(() {
      _selectedAnswer = -1; // -1 indicates timeout
      _answered = true;
    });

    // Auto-proceed from timeout
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _advance();
    });
  }

  Future<void> _confirmExitAndPenalize() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF13132A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Give Up?',
          style: GoogleFonts.poppins(color: const Color(0xFFFF3D71), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Exiting the challenge now is considered retreating! You will lose 15 XP. Are you sure you want to quit?',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Stay', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3D71)),
            child: Text('Quit & Lose XP', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (exit == true && mounted) {
      final user = context.read<UserModel>();
      final db = context.read<DatabaseService>();
      
      // Cheater/Retreat penalty: 15 XP
      int penalty = 15;
      await db.deductXP(userModel: user, penalty: penalty);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: const Text('You fled the challenge and lost 15 XP!'),
           backgroundColor: const Color(0xFFFF3D71),
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
         ));
         Navigator.of(context).pop(); // Actually pop the screen
      }
    }
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Interactions ──────────────────────────

  void _selectAnswer(int index) {
    if (_answered) return;
    _questionTimer?.cancel(); // stop timer when they answer
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _current.correctAnswerIndex) _score++;
    });

    // Auto-proceed after short delay so user sees correct/wrong result
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _advance();
    });
  }

  Future<void> _advance() async {
    final isLast = _currentIndex == _total - 1;
    if (isLast) {
      await _finish();
    } else {
      // Fade out → update state → fade in
      await _fadeController.reverse();
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _startTimerForQuestion();
      await _fadeController.forward();
    }
  }

  // ── Coin helpers ──────────────────────────
  /// Returns the coin reward for the current challenge difficulty.
  int get _coinRewardForDifficulty {
    switch (widget.challenge.difficulty.toLowerCase()) {
      case 'hard':
        return 20;
      case 'medium':
        return 10;
      case 'easy':
      default:
        return 5;
    }
  }

  Future<void> _finish() async {
    final bool passed = _score / _total > 0.6;
    List<String> newBadges = [];
    bool wasNewCompletion = false;
    int coinsEarned = 0;
    bool lessonUnlocked = false;

    if (context.mounted) {
      final user = context.read<UserModel>();
      final db = context.read<DatabaseService>();

      if (passed) {
        final prefs = await SharedPreferences.getInstance();

        // ── DUAL-LOCK XP PROTECTION ──────────────────────────────────────
        // Lock 1 (Local): A permanent SharedPreferences flag that is written
        //   once when XP is first earned and NEVER cleared. This survives
        //   network outages, fresh installs, and Firebase sync delays.
        // Lock 2 (Remote): completedChallengeIds in Firebase via
        //   markChallengeCompleted(). Acts as the canonical server record.
        // XP is only awarded when BOTH locks confirm it's a first-time pass.
        final xpLockKey = 'ch_xp_earned_${user.uid}_${widget.challenge.id}';
        final alreadyEarnedXPLocally = prefs.getBool(xpLockKey) ?? false;

        // Always update the 24h replay cooldown timer
        await prefs.setString(
          'ch_last_run_${user.uid}_${widget.challenge.id}',
          DateTime.now().toIso8601String(),
        );

        if (!alreadyEarnedXPLocally) {
          // Lock 2 check — also updates Firebase completedChallengeIds
          wasNewCompletion = user.markChallengeCompleted(widget.challenge.id);

          if (wasNewCompletion) {
            // Write the permanent local XP lock BEFORE awaiting network calls
            // so a crash/disconnect between the two can't cause double-award.
            await prefs.setBool(xpLockKey, true);

            await db.awardXP(
              userModel: user,
              xpAmount: widget.challenge.xpReward,
            );
            newBadges = await db.checkAndUnlockBadges(userModel: user);

            // ── COIN REWARD (first-time pass only) ──────────────────────
            coinsEarned = _coinRewardForDifficulty;
            await db.awardCoins(userModel: user, coinAmount: coinsEarned);

            // ── LESSON PROGRESSION ───────────────────────────────────────
            final categoryPrefix = widget.challenge.id.split('_').first;
            final allIds =
                Challenge.allChallenges().map((c) => c.id).toList();
            lessonUnlocked = await db.checkAndIncrementLesson(
              userModel: user,
              categoryPrefix: categoryPrefix,
              allChallengeIds: allIds,
            );

            if (lessonUnlocked && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Text('🎓', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lesson Complete! All ${categoryPrefix.toUpperCase()} challenges cleared!',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF8A38F5),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            // Firebase says already completed but local lock was missing.
            // Write local lock now to prevent future issues, save no XP.
            await prefs.setBool(xpLockKey, true);
            await db.saveUserModel(user);
          }
        } else {
          // Local lock says XP was already earned — skip everything.
          // Still update Firebase completion list silently if needed.
          if (!user.completedChallengeIds.contains(widget.challenge.id)) {
            user.markChallengeCompleted(widget.challenge.id);
            await db.saveUserModel(user);
          }
        }
      }
    }

    if (context.mounted) {
      await _showResultDialog(
        passed: passed,
        newBadges: newBadges,
        isPracticeRun: passed && !wasNewCompletion,
        coinsEarned: coinsEarned,
      );
    }
  }

  Future<void> _showResultDialog({
    required bool passed,
    List<String> newBadges = const [],
    bool isPracticeRun = false,
    int coinsEarned = 0,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<UserModel>();
    final allChallenges = widget.challenge.findNextChallenge(user);

    // ── FAILURE BUY-IN DIALOG ─────────────────────────
    // If the user failed AND the challenge is not yet completed (not review mode),
    // offer an immediate retake for a 10-coin buy-in.
    if (!passed && !user.completedChallengeIds.contains(widget.challenge.id)) {
      final retake = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _BuyInDialog(
          challenge: widget.challenge,
          isDark: isDark,
          userCoins: user.coins,
        ),
      );

      if (retake == true && context.mounted) {
        final db = context.read<DatabaseService>();
        final spent = await db.spendCoins(userModel: user, cost: 10);
        if (spent && mounted) {
          // Replace current route with a fresh challenge screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ChallengeScreen(challenge: widget.challenge),
            ),
          );
          return;
        } else if (mounted) {
          // Coins ran out between dialog display and tap (race condition guard)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Not enough coins to retry!'),
              backgroundColor: const Color(0xFFFF3D71),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      }
      // User chose not to retake — fall through to normal failure result dialog
      if (!context.mounted) return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ResultDialog(
        passed: passed,
        score: _score,
        total: _total,
        xpReward: passed && !isPracticeRun ? widget.challenge.xpReward : 0,
        coinsEarned: coinsEarned,
        isDark: isDark,
        newBadges: newBadges,
        nextChallenge: allChallenges,
        isPracticeRun: isPracticeRun,
        onDismiss: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
        onNextChallenge: allChallenges != null
            ? () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        ChallengeScreen(challenge: allChallenges),
                  ),
                );
              }
            : null,
      ),
    );
  }


  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        _confirmExitAndPenalize();
      },
      child: GlassScaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildTimerBar(isDark),
                        const SizedBox(height: 16),
                        _buildQuestionCard(isDark)
                            .animate()
                            .slideY(begin: 0.08, duration: 400.ms)
                            .fadeIn(),
                        const SizedBox(height: 24),
                        _buildAnswerOptions(isDark),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: back + progress ───────────────
  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.textSecondary : Colors.black87;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor, size: 20),
                onPressed: _confirmExitAndPenalize,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.challenge.title,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Question ${_currentIndex + 1} of $_total',
                      style: GoogleFonts.poppins(
                        color: subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Difficulty badge
              _DifficultyBadge(difficulty: widget.challenge.difficulty),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearPercentIndicator(
              lineHeight: 8.0,
              percent: _progress,
              padding: EdgeInsets.zero,
              barRadius: const Radius.circular(50),
              backgroundColor:
                  isDark ? Colors.white10 : Colors.black.withOpacity(0.07),
              linearGradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              animation: true,
              animationDuration: 400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Timer Bar ──────────────────────────────
  Widget _buildTimerBar(bool isDark) {
    if (_maxTime == 0) return const SizedBox.shrink();
    
    double ratio = _timeRemaining / _maxTime;
    Color timerColor = const Color(0xFF00E5FF);
    if (ratio < 0.3) {
      timerColor = const Color(0xFFFF3D71); // Red when urgent
    } else if (ratio < 0.6) {
      timerColor = const Color(0xFFFFBD2E); // Yellow
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
              Row(
                children: [
                   Icon(Icons.timer_outlined, color: timerColor, size: 18),
                   const SizedBox(width: 6),
                   Text(
                     '$_timeRemaining s',
                     style: GoogleFonts.poppins(
                       color: timerColor,
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                     )
                   )
                ]
              ),
              if (_timeRemaining == 0)
                Text(
                  'Time\'s Up!',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF3D71), 
                    fontWeight: FontWeight.w700, 
                    fontSize: 13
                  )
                ).animate().fadeIn().shake(duration: const Duration(milliseconds: 500))
           ]
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
            lineHeight: 6.0,
            percent: ratio.clamp(0.0, 1.0),
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(50),
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            progressColor: timerColor,
            animation: false,
        ),
      ],
    );
  }

  // ── Question card ─────────────────────────
  Widget _buildQuestionCard(bool isDark) {
    return _GlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.quiz_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Question',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _current.questionText,
            style: GoogleFonts.poppins(
              color: isDark ? AppColors.textPrimary : AppColors.lightText,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          // Code snippet block
          if (_current.codeSnippet != null) ...[
            const SizedBox(height: 20),
            _CodeBlock(code: _current.codeSnippet!),
          ],
        ],
      ),
    );
  }

  // ── Answer options ────────────────────────
  Widget _buildAnswerOptions(bool isDark) {
    return Column(
      children: List.generate(_current.options.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AnswerTile(
            label: _current.options[i],
            index: i,
            selectedIndex: _selectedAnswer,
            correctIndex: _current.correctAnswerIndex,
            answered: _answered,
            isDark: isDark,
            onTap: () => _selectAnswer(i),
          ).animate(delay: (i * 80).ms).slideX(begin: 0.1).fadeIn(),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  _AnswerTile
//  Individual answer option that highlights
//  correct/incorrect after selection.
// ─────────────────────────────────────────────
class _AnswerTile extends StatelessWidget {
  final String label;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final bool answered;
  final bool isDark;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.answered,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine visual state
    Color borderColor;
    Color bgColor;
    Color textColor;
    Widget? trailingIcon;

    if (!answered) {
      // Default idle style
      borderColor = isDark
          ? AppColors.primary.withOpacity(0.3)
          : AppColors.primary.withOpacity(0.25);
      bgColor = isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.white.withOpacity(0.85);
      textColor = isDark ? AppColors.textPrimary : AppColors.lightText;
    } else if (index == correctIndex) {
      // Always highlight correct answer
      borderColor = const Color(0xFF00C853);
      bgColor = const Color(0xFF00C853).withOpacity(0.12);
      textColor = const Color(0xFF00C853);
      trailingIcon = const Icon(Icons.check_circle_rounded,
          color: Color(0xFF00C853), size: 20);
    } else if (index == selectedIndex) {
      // Wrong selection
      borderColor = AppColors.hpBar;
      bgColor = AppColors.hpBar.withOpacity(0.1);
      textColor = AppColors.hpBar;
      trailingIcon = const Icon(Icons.cancel_rounded,
          color: AppColors.hpBar, size: 20);
    } else {
      // Unselected, dimmed
      borderColor = isDark
          ? Colors.white12
          : Colors.black.withOpacity(0.08);
      bgColor = isDark
          ? Colors.white.withOpacity(0.02)
          : Colors.white.withOpacity(0.5);
      textColor = isDark ? AppColors.textHint : Colors.black87;
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: answered && index == correctIndex
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Option letter badge
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                String.fromCharCode(65 + index), // A, B, C, D
                style: GoogleFonts.poppins(
                  color: borderColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 10),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _CodeBlock
//  Terminal-style container for code snippets.
// ─────────────────────────────────────────────
class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117), // GitHub dark
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Window controls (cosmetic)
          Row(
            children: [
              _dot(const Color(0xFFFF5F57)),
              const SizedBox(width: 6),
              _dot(const Color(0xFFFFBD2E)),
              const SizedBox(width: 6),
              _dot(const Color(0xFF28C840)),
              const SizedBox(width: 12),
              Text(
                'code',
                style: GoogleFonts.sourceCodePro(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            code,
            style: GoogleFonts.sourceCodePro(
              color: const Color(0xFFE6EDF3),
              fontSize: 13.5,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ─────────────────────────────────────────────
//  _GlassCard
//  Reusable glassmorphism container card.
// ─────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _DifficultyBadge
//  Colored badge for challenge difficulty.
// ─────────────────────────────────────────────
class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'hard':
        return AppColors.hpBar;
      case 'medium':
        return AppColors.gold;
      default:
        return AppColors.xpBar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.poppins(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _ResultDialog
//  Glassmorphism success/failure dialog shown
//  at the end of the challenge.
// ─────────────────────────────────────────────
class _ResultDialog extends StatelessWidget {
  final bool passed;
  final int score;
  final int total;
  final int xpReward;
  final int coinsEarned; // 0 in review/practice mode
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback? onNextChallenge;
  final List<String> newBadges;
  final Challenge? nextChallenge;
  final bool isPracticeRun; // true = retake, no XP awarded

  const _ResultDialog({
    required this.passed,
    required this.score,
    required this.total,
    required this.xpReward,
    required this.isDark,
    required this.onDismiss,
    this.onNextChallenge,
    this.newBadges = const [],
    this.nextChallenge,
    this.isPracticeRun = false,
    this.coinsEarned = 0,
  });

  static const Map<String, String> _badgeNames = {
    'python_master': '🐍 Python Master',
    'sql_query': '🗄️ SQL Query',
    'streak_10': '🔥 10-Day Streak',
    'challenge_ace': '🏅 Challenge Ace',
    'data_analysis': '📊 Data Analysis',
    'api_explorer': '🚀 API Explorer',
  };

  @override
  Widget build(BuildContext context) {
    // Practice run gets its own amber accent so it visually differs from a
    // first-time pass (green) and a failure (red).
    final Color accentColor = !passed
        ? AppColors.hpBar
        : isPracticeRun
            ? const Color(0xFFFFBD2E) // amber = practice
            : const Color(0xFF00C853); // green = first-time pass

    final String emoji = !passed
        ? '😔'
        : isPracticeRun
            ? '📚'
            : '🏆';

    final String headline = !passed
        ? 'Not Quite!'
        : isPracticeRun
            ? 'Practice Complete!'
            : 'Challenge Passed!';

    final String subtitle = !passed
        ? 'You need > 60% to pass. Spend 10 coins to retry immediately!'
        : isPracticeRun
            ? 'Great effort! This was a practice run — XP & coins are earned only on first completion.'
            : 'Great work! You earned XP and coins for this challenge!';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.bgCard.withOpacity(0.92)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: accentColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accentColor.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 38)),
                  ),
                )
                    .animate(delay: 100.ms)
                    .scale(begin: const Offset(0.5, 0.5))
                    .fadeIn(),
                const SizedBox(height: 16),
                Text(
                  headline,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppColors.lightText,
                  ),
                ).animate(delay: 200.ms).slideY(begin: 0.2).fadeIn(),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondary : Colors.black87,
                    height: 1.5,
                  ),
                ).animate(delay: 250.ms).fadeIn(),
                const SizedBox(height: 20),
                // Score row
                _ScoreRow(
                  score: score,
                  total: total,
                  isDark: isDark,
                  accentColor: accentColor,
                ).animate(delay: 300.ms).slideY(begin: 0.1).fadeIn(),
                // XP row and Coin row — only shown on genuine first-time pass
                if (passed && !isPracticeRun) ...[
                  const SizedBox(height: 10),
                  _XpRow(xp: xpReward)
                      .animate(delay: 380.ms)
                      .slideY(begin: 0.1)
                      .fadeIn(),
                  if (coinsEarned > 0) ...[
                    const SizedBox(height: 8),
                    _CoinRow(coins: coinsEarned)
                        .animate(delay: 410.ms)
                        .slideY(begin: 0.1)
                        .fadeIn(),
                  ],
                ],
                // Practice-run info banner
                if (isPracticeRun) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBD2E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFBD2E).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFFFFBD2E), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'XP is earned only once per challenge. Keep practising to sharpen your skills!',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFBD2E),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 380.ms).slideY(begin: 0.1).fadeIn(),
                ],
                // Newly unlocked badges
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _BadgesUnlockedRow(
                    badgeIds: newBadges,
                    badgeNames: _badgeNames,
                    isDark: isDark,
                  ).animate(delay: 420.ms).slideY(begin: 0.1).fadeIn(),
                ],
                const SizedBox(height: 22),
                // Primary action button
                CustomButton(
                  label: isPracticeRun
                      ? 'Done'
                      : passed
                          ? 'Claim Reward'
                          : 'Try Again Later',
                  icon: isPracticeRun
                      ? Icons.check_rounded
                      : passed
                          ? Icons.bolt_rounded
                          : Icons.arrow_back_rounded,
                  onPressed: onDismiss,
                  gradientColors: isPracticeRun
                      ? [const Color(0xFFFFBD2E), const Color(0xFFFF9800)]
                      : passed
                          ? [const Color(0xFF00C853), const Color(0xFF00E5FF)]
                          : null,
                ).animate(delay: 450.ms).slideY(begin: 0.15).fadeIn(),
                // Next challenge button (only on first-time wins, not practice)
                if (onNextChallenge != null &&
                    nextChallenge != null &&
                    !isPracticeRun) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onNextChallenge,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.skip_next_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Next: ${nextChallenge!.title}',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: 500.ms).slideY(begin: 0.1).fadeIn(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int score;
  final int total;
  final bool isDark;
  final Color accentColor;

  const _ScoreRow({
    required this.score,
    required this.total,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((score / total) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, color: accentColor, size: 22),
          const SizedBox(width: 10),
          Text(
            'Score: $score / $total',
            style: GoogleFonts.poppins(
              color: isDark ? AppColors.textPrimary : AppColors.lightText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($pct%)',
            style: GoogleFonts.poppins(
              color: accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  final int xp;
  const _XpRow({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          Text(
            '+$xp XP Earned!',
            style: GoogleFonts.poppins(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _BadgesUnlockedRow
//  Shows newly unlocked badge names in the result dialog.
// ─────────────────────────────────────────────
class _BadgesUnlockedRow extends StatelessWidget {
  final List<String> badgeIds;
  final Map<String, String> badgeNames;
  final bool isDark;

  const _BadgesUnlockedRow({
    required this.badgeIds,
    required this.badgeNames,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded,
                  color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 6),
              Text(
                'New Badge${badgeIds.length > 1 ? 's' : ''} Unlocked!',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badgeIds.map((id) {
              final name = badgeNames[id] ?? id;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5)),
                ),
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _CoinRow
//  Gold-themed reward row shown in the result dialog.
// ─────────────────────────────────────────────
class _CoinRow extends StatelessWidget {
  final int coins;
  const _CoinRow({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '+$coins Coins Earned!',
            style: GoogleFonts.poppins(
              color: const Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _BuyInDialog
//  Shown when a user fails a not-yet-completed challenge.
//  Offers an immediate retake for 10 coins.
// ─────────────────────────────────────────────
class _BuyInDialog extends StatelessWidget {
  final Challenge challenge;
  final bool isDark;
  final int userCoins;

  const _BuyInDialog({
    required this.challenge,
    required this.isDark,
    required this.userCoins,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAfford = userCoins >= 10;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.bgCard.withOpacity(0.95)
                  : Colors.white.withOpacity(0.97),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFF3D71).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3D71).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3D71).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFFF3D71).withOpacity(0.5),
                        width: 2),
                  ),
                  child: const Center(
                    child: Text('💸', style: TextStyle(fontSize: 34)),
                  ),
                )
                    .animate(delay: 50.ms)
                    .scale(begin: const Offset(0.6, 0.6))
                    .fadeIn(),
                const SizedBox(height: 16),
                Text(
                  'Want to Try Again?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppColors.lightText,
                  ),
                ).animate(delay: 120.ms).slideY(begin: 0.2).fadeIn(),
                const SizedBox(height: 8),
                Text(
                  canAfford
                      ? 'Spend 10 🪙 coins for an immediate retake of "${challenge.title}".'
                      : 'You need 10 🪙 coins to retry immediately.\nYour balance: $userCoins coins.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondary : Colors.black87,
                    height: 1.5,
                  ),
                ).animate(delay: 160.ms).fadeIn(),
                const SizedBox(height: 6),
                // Coin balance chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Your balance: $userCoins coins',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 22),
                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canAfford
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      canAfford ? 'Retry for 10 Coins' : 'Not Enough Coins',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford
                          ? const Color(0xFFFF3D71)
                          : Colors.grey.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ).animate(delay: 250.ms).slideY(begin: 0.1).fadeIn(),
                const SizedBox(height: 10),
                // Decline button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? AppColors.textSecondary : Colors.black54,
                      side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'No Thanks, Exit',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ).animate(delay: 290.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
