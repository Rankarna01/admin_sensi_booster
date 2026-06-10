import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable card with subtle green glow effect.
/// Used across all pages for consistent elegant card design.
class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool glow; // Whether to show the green glow
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlowCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.glow = false,
    this.borderRadius = 14,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? (glow ? AppColors.neonGreen.withOpacity(0.25) : AppColors.border),
          width: 1,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.neonGreen.withOpacity(0.06),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppColors.cardShadow(),
      ),
      child: child,
    );
  }
}
