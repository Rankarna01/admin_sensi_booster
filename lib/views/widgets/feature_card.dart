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
  final Widget? iconWidget;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.isActive,
    required this.isAllowed,
    this.onChanged,
    this.extraContent,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOn = isAllowed && isActive;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOn ? AppColors.cardElevated : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.transparent,
              width: 0,
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
                  // Left side: Icon + Texts
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Huge Watermark-style Icon
                        if (iconWidget != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                iconTheme: IconThemeData(
                                  color: isOn ? AppColors.neonGreen : AppColors.textMuted.withOpacity(0.1),
                                  size: 45,
                                  shadows: isOn ? [Shadow(color: AppColors.neonGreen.withOpacity(0.8), blurRadius: 8)] : null,
                                ),
                              ),
                              child: iconWidget!,
                            ),
                          ),
                        ],
                        // Texts Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.orbitron(
                                        color: isAllowed ? AppColors.textWhite : AppColors.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
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
                              Text(
                                description,
                                style: GoogleFonts.inter(
                                  color: isAllowed ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.5),
                                  fontSize: 11,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Sci-Fi Switch
                  SciFiSwitch(
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
        ),
        
        // Glowing Green Left Edge
        Positioned(
          left: 0,
          top: 32, // Vertically centered with the icon
          child: Container(
            width: 3,
            height: 36, // Fixed height so it doesn't stretch too much
            decoration: BoxDecoration(
              color: AppColors.neonGreen,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: isOn ? [
                BoxShadow(
                  color: AppColors.neonGreen,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : [],
            ),
          ),
        ),
      ],
    );
  }
}

class SciFiSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SciFiSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onChanged == null;
    
    return GestureDetector(
      onTap: () {
        if (!isDisabled) {
          onChanged!(!value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.neonGreen.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDisabled 
                ? AppColors.border.withOpacity(0.3) 
                : (value ? AppColors.neonGreen : AppColors.border),
            width: 1.5,
          ),
          boxShadow: value && !isDisabled
              ? [BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)]
              : [],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isDisabled 
                  ? AppColors.textMuted.withOpacity(0.2) 
                  : (value ? AppColors.neonGreen : AppColors.textMuted),
              borderRadius: BorderRadius.circular(3),
              boxShadow: value && !isDisabled
                  ? [BoxShadow(color: AppColors.neonGreen, blurRadius: 5)]
                  : [],
            ),
          ),
        ),
      ),
    );
  }
}
