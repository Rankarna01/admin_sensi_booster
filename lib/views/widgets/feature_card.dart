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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAllowed ? AppColors.border : Colors.redAccent.withOpacity(0.3), width: 1),
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
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isAllowed ? AppColors.textWhite : AppColors.textMuted, 
                              fontSize: 14, 
                              fontWeight: FontWeight.bold
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isAllowed) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.lock, size: 8, color: Colors.white),
                                const SizedBox(width: 2),
                                Text("LOCKED", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: isAllowed ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.5), fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Switch Neon Green
              Switch(
                value: isAllowed ? isActive : false,
                onChanged: isAllowed ? onChanged : null,
                activeColor: AppColors.background,
                activeTrackColor: AppColors.neonGreen,
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.background,
              )
            ],
          ),
          if (isActive && extraContent != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            extraContent!,
          ]
        ],
      ),
    );
  }
}
