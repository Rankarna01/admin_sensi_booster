import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/client_bottom_nav.dart';
import '../widgets/neon_loading.dart';
import '../home/home_view.dart';
import '../feature/feature_view.dart';
import '../visual/visual_view.dart';
import '../profile/profile_view.dart';

class ClientMainLayout extends StatefulWidget {
  const ClientMainLayout({super.key});

  @override
  State<ClientMainLayout> createState() => _ClientMainLayoutState();
}

class _ClientMainLayoutState extends State<ClientMainLayout> {
  int _currentIndex = 0;
  bool _isTransitioning = false;

  final List<Widget> _pages = [
    const HomeView(),
    const FeatureView(),
    const VisualView(),
    const ProfileView(),
  ];

  void _onTabChange(int index) {
    if (index == _currentIndex) return;
    
    setState(() { _isTransitioning = true; });
    
    // Short delay for smooth transition feel
    Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _currentIndex = index;
          _isTransitioning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient glow top
          Positioned(
            top: -120, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonGreen.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Konten Utama
          SafeArea(
            child: Stack(
              children: [
                // Page Content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _pages[_currentIndex],
                ),

                // Loading Overlay during transition
                if (_isTransitioning)
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, opacity, _) {
                        return Container(
                          color: AppColors.background.withOpacity(0.6 * opacity),
                          child: Opacity(
                            opacity: opacity,
                            child: const NeonLoading(size: 26),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Bottom Navbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClientBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabChange,
            ),
          ),
        ],
      ),
    );
  }
}
