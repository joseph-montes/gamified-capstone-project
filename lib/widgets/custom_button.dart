import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  CustomButton
//  A flexible, gradient-ready animated button
//  used throughout the app.
// ─────────────────────────────────────────────
class CustomButton extends StatefulWidget {
  /// Button label text.
  final String label;

  /// Callback when pressed. Pass null to disable.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Show a loading spinner instead of the label.
  final bool isLoading;

  /// Render an outlined (secondary) style instead of filled.
  final bool isOutlined;

  /// Optional explicit width; defaults to full width.
  final double? width;

  /// Optional explicit height.
  final double height;

  /// Override the gradient colors.
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = 54,
    this.gradientColors,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  // ─────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final gradient = widget.gradientColors != null
        ? LinearGradient(colors: widget.gradientColors!)
        : AppColors.primaryGradient;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: widget.height,
            child: widget.isOutlined
                ? _buildOutlinedButton(gradient)
                : _buildFilledButton(gradient, isDisabled),
          ),
        ),
      ),
    );
  }

  // ── Filled (Primary) Variant ──────────────
  Widget _buildFilledButton(LinearGradient gradient, bool isDisabled) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [
                  AppColors.textHint.withOpacity(0.4),
                  AppColors.textHint.withOpacity(0.4)
                ],
              )
            : gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                )
              ],
      ),
      child: _buildContent(Colors.white),
    );
  }

  // ── Outlined (Secondary) Variant ──────────
  Widget _buildOutlinedButton(LinearGradient gradient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: _buildContent(AppColors.primary),
    );
  }

  // ── Inner Content ─────────────────────────
  Widget _buildContent(Color contentColor) {
    return Center(
      child: widget.isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(contentColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: contentColor, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: contentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  XpBadge
//  Small inline badge showing an XP amount.
// ─────────────────────────────────────────────
class XpBadge extends StatelessWidget {
  final int xp;
  final bool compact;

  const XpBadge({super.key, required this.xp, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: AppColors.accent, size: compact ? 12 : 16),
          const SizedBox(width: 4),
          Text(
            '+$xp XP',
            style: GoogleFonts.poppins(
              color: AppColors.accent,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CoinBadge
//  Small inline badge showing a coin amount.
// ─────────────────────────────────────────────
class CoinBadge extends StatelessWidget {
  final int coins;
  const CoinBadge({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 14),
          const SizedBox(width: 4),
          Text(
            '+$coins',
            style: GoogleFonts.poppins(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LevelUpDialog
//  Call this after awarding XP that causes a level-up.
// ─────────────────────────────────────────────
class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  final String rankTitle;
  final VoidCallback onContinue;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.rankTitle,
    required this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String rankTitle,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpDialog(
        newLevel: newLevel,
        rankTitle: rankTitle,
        onContinue: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 4,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star burst icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(Icons.military_tech_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              '🎉 Level Up!',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reached Level $newLevel',
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              rankTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              label: 'Continue',
              onPressed: onContinue,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
