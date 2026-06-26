import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/client_provider.dart';
import '../feature/smart_touch_dashboard.dart' as import_dashboard;
import '../feature/game_launcher_view.dart' as import_launcher;
import '../feature/red_magic_view.dart' as import_redmagic;

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with SingleTickerProviderStateMixin {
  static const MethodChannel _overlayChannel = MethodChannel('com.mfw.sensi_booster/overlay');
  
  File? _customPhoto;
  List<AppInfo> _allApps = [];
  List<String> _addedPackageNames = [];
  bool _isLoadingApps = true;

  @override
  void initState() {
    super.initState();
    _checkInitialSmartTouchIntent();
    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'showSmartTouchDashboard') {
        _showSmartTouchDashboard();
      }
    });
    _loadCustomPhoto();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final prefs = await SharedPreferences.getInstance();
    final packages = prefs.getStringList('added_games') ?? [];
    
    try {
      final apps = await InstalledApps.getInstalledApps(excludeSystemApps: true, withIcon: true);
      setState(() {
        _allApps = apps;
        _addedPackageNames = packages;
        _isLoadingApps = false;
      });
    } catch (e) {
      debugPrint("Error loading apps: $e");
      setState(() {
        _isLoadingApps = false;
      });
    }
  }

  Future<void> _loadCustomPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('custom_photo_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _customPhoto = File(path);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _customPhoto = File(pickedFile.path);
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_photo_path', pickedFile.path);
      }
    } catch (e) {
      debugPrint("Gagal memilih foto: $e");
    }
  }

  Future<void> _checkInitialSmartTouchIntent() async {
    try {
      final bool opened = await _overlayChannel.invokeMethod('checkSmartTouchIntent') ?? false;
      if (opened) _showSmartTouchDashboard();
    } catch (e) {
      debugPrint("Gagal cek intent awal: $e");
    }
  }

  void _showSmartTouchDashboard() {
    import_dashboard.SmartTouchDashboard.show(context);
  }

  void _showKelolaGamesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40, height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Kelola Game", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoadingApps 
                            ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _allApps.length,
                                itemBuilder: (context, index) {
                                  final app = _allApps[index];
                                  final isAdded = _addedPackageNames.contains(app.packageName);
                                  
                                  return ListTile(
                                    leading: app.icon != null 
                                        ? Image.memory(app.icon!, width: 40, height: 40) 
                                        : const Icon(Icons.android, color: AppColors.neonGreen),
                                    title: Text(app.name ?? "Unknown", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                    subtitle: Text(app.packageName ?? "", style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                                    trailing: GestureDetector(
                                      onTap: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        if (isAdded) {
                                          _addedPackageNames.remove(app.packageName);
                                        } else {
                                          _addedPackageNames.add(app.packageName!);
                                        }
                                        await prefs.setStringList('added_games', _addedPackageNames);
                                        setState(() {}); 
                                        setModalState(() {}); 
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isAdded ? Colors.redAccent.withOpacity(0.1) : AppColors.neonGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: isAdded ? Colors.redAccent.withOpacity(0.5) : AppColors.neonGreen.withOpacity(0.5)),
                                        ),
                                        child: Text(isAdded ? "Hapus" : "Tambah", style: GoogleFonts.inter(color: isAdded ? Colors.redAccent : AppColors.neonGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pkgAsync = ref.watch(currentPackageProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    // Check if the current package is a VIP package (either it costs money or the name contains 'vip')
    final isVip = pkgAsync.value != null && ((pkgAsync.value!.price > 0) || (pkgAsync.value!.name.toLowerCase().contains('vip')));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 36, bottom: 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 42, 
                      height: 42,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: AppColors.neonGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "MFW APPS",
                      style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow(),
                  ),
                  child: isVip
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 18)
                      : Icon(Icons.check_circle_outline_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 18),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // Welcome Section
            userAsync.when(
              data: (user) => Text(
                "Welcome, ${user?.email.split('@').first ?? 'randy'}",
                style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              loading: () => const Text("Welcome, ...", style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
              error: (_, __) => const Text("Welcome, randy", style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(width: 2, height: 14, color: AppColors.neonGreen),
                const SizedBox(width: 8),
                Text(
                  "Optimize your gaming experience",
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Custom Photo Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.surface,
                    AppColors.neonGreen.withOpacity(0.15),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: AppColors.neonGreen.withOpacity(0.05), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "CUSTOM\n",
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
                              ),
                              TextSpan(
                                text: "PHOTO",
                                style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Unggah foto favoritmu\ndan tampilkan di sini!",
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.neonGreen.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.upload_rounded, color: AppColors.neonGreen, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "PILIH FOTO",
                                  style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Stacked photo cards placeholder
                        Transform.translate(
                          offset: const Offset(-10, -10),
                          child: Transform.rotate(
                            angle: -0.1,
                            child: Container(
                              width: 100, height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2126),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 110, height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF262A33),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                            image: _customPhoto != null
                                ? DecorationImage(
                                    image: FileImage(_customPhoto!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _customPhoto == null
                              ? const Center(
                                  child: Icon(Icons.landscape_rounded, color: AppColors.neonGreen, size: 48),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: -5, right: -5,
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              width: 32, height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.neonGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.black, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // My Games Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Games",
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                GestureDetector(
                  onTap: _showKelolaGamesBottomSheet,
                  child: Row(
                    children: [
                      Text(
                        "Kelola",
                        style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.neonGreen, size: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Games List
            if (_isLoadingApps)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
              )
            else if (_addedPackageNames.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text("Belum ada game yang ditambahkan.", style: GoogleFonts.inter(color: Colors.white54)),
                ),
              )
            else
              ..._addedPackageNames.map((pkgName) {
                final appIndex = _allApps.indexWhere((a) => a.packageName == pkgName);
                if (appIndex == -1) return const SizedBox();
                return _buildGameItem(app: _allApps[appIndex]);
              }),
            
            // ROG Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const import_launcher.GameLauncherView()),
                );
              },
              child: _buildSpecialItem(
                title: "Monitoring ROG",
                iconWidget: SvgPicture.asset('assets/images/logo-rog.svg', width: 26, height: 26),
                glowColor: const Color(0xFFFF3B30),
              ),
            ),
            
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const import_redmagic.RedMagicView()),
                );
              },
              child: _buildSpecialItem(
                title: "RedMagic",
                iconWidget: Image.asset(
                  'assets/images/red-magic.png',
                  width: 26,
                  height: 26,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const Icon(Icons.sports_esports, color: Color(0xFFFF3B30), size: 26),
                ),
                glowColor: const Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameItem({required AppInfo app}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: app.icon != null 
                ? Image.memory(app.icon!, width: 28, height: 28) 
                : const Icon(Icons.videogame_asset, color: AppColors.neonGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name ?? "Unknown", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Text(app.packageName ?? "", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
            ),
            child: Text("Added", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialItem({required String title, required Widget iconWidget, Color glowColor = AppColors.neonGreen}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.card, AppColors.card.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glowColor.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.1),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: glowColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: glowColor.withOpacity(0.5), width: 1.5),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: glowColor.withOpacity(0.8), size: 16),
        ],
      ),
    );
  }

}
