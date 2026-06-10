import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isActive;
  final bool isAllowed;
  final ValueChanged<bool>? onChanged;
  final Widget? extraContent;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.isActive,
    required this.isAllowed,
    this.onChanged,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOn = isAllowed && isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOn ? AppColors.cardElevated : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn
              ? AppColors.neonGreen.withOpacity(0.3)
              : isAllowed
                  ? AppColors.border
                  : Colors.redAccent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: AppColors.neonGreen.withOpacity(0.06),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : AppColors.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status indicator dot
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOn
                                ? AppColors.neonGreen
                                : isAllowed
                                    ? AppColors.textMuted
                                    : Colors.redAccent.withOpacity(0.6),
                            boxShadow: isOn
                                ? [
                                    BoxShadow(
                                      color: AppColors.neonGreen.withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              color: isAllowed ? AppColors.textWhite : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isAllowed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 0.5),
                            ),
                            child: Text(
                              "LOCKED",
                              style: GoogleFonts.inter(
                                color: Colors.redAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text(
                        description,
                        style: GoogleFonts.inter(
                          color: isAllowed ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.5),
                          fontSize: 11,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Switch
              Switch(
                value: isAllowed ? isActive : false,
                onChanged: isAllowed ? onChanged : null,
              ),
            ],
          ),
          if (isActive && extraContent != null) ...[
            const SizedBox(height: 14),
            Divider(color: AppColors.border.withOpacity(0.5)),
            const SizedBox(height: 14),
            extraContent!,
          ]
        ],
      ),
    );
  }
}
