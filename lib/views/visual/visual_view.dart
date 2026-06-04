import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class VisualView extends StatelessWidget {
  const VisualView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Visual View Coming Soon",
        style: TextStyle(color: AppColors.textWhite),
      ),
    );
  }
}
