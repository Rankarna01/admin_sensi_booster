import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Simple, elegant loading spinner with subtle neon green glow.
/// Used for page transitions and data loading states.
class NeonLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final String? message;

  const NeonLoading({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.5,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonGreen.withOpacity(0.1 + (value * 0.15)),
                        blurRadius: 12 + (value * 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    value: null,
                    strokeWidth: strokeWidth,
                    color: AppColors.neonGreen.withOpacity(0.6 + (value * 0.4)),
                    strokeCap: StrokeCap.round,
                  ),
                );
              },
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.textMuted.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay for page transitions.
class PageLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const PageLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              builder: (context, opacity, _) {
                return Container(
                  color: AppColors.background.withOpacity(0.7 * opacity),
                  child: const NeonLoading(size: 32),
                );
              },
            ),
          ),
      ],
    );
  }
}
