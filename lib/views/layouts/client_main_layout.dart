import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/client_bottom_nav.dart';
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
  int _currentIndex = 0; // Default diatur ke HomeView (index 0)

  // Daftar 4 Halaman Utama
  final List<Widget> _pages = [
    const HomeView(),
    const FeatureView(),
    const VisualView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Konten Utama
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
            
            // Bottom Navbar Melayang (Floating)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClientBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}