import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:admin_sensi_booster/views/feature/game_boost_landscape_view.dart';
import 'package:admin_sensi_booster/core/constants/app_colors.dart';

class GameIntroVideoView extends StatefulWidget {
  final String appName;
  final String packageName;

  const GameIntroVideoView({
    Key? key,
    required this.appName,
    required this.packageName,
  }) : super(key: key);

  @override
  State<GameIntroVideoView> createState() => _GameIntroVideoViewState();
}

class _GameIntroVideoViewState extends State<GameIntroVideoView> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // Posisikan HP landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = VideoPlayerController.asset('assets/images/video.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.play();
        
        // Cek jika video sudah selesai
        _controller.addListener(_videoListener);
      }).catchError((e) {
        // Jika video gagal diload (misal file belum ada), langsung skip saja
        debugPrint("Video load error: $e");
        _navigateToMFWCenter();
      });
  }

  void _videoListener() {
    if (_controller.value.isInitialized &&
        !_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration) {
      _navigateToMFWCenter();
    }
  }

  void _navigateToMFWCenter() {
    _controller.removeListener(_videoListener);
    _controller.pause();
    
    // Replace layar saat ini dengan MFW Center
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameBoostLandscapeView(
          appName: widget.appName,
          packageName: widget.packageName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
          
          // Tombol Skip di sebelah kiri
          Positioned(
            left: 30,
            bottom: 30,
            child: SafeArea(
              child: GestureDetector(
                onTap: _navigateToMFWCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.skip_next_rounded, color: AppColors.neonGreen, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "Klik tombol skip untuk skip video",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
