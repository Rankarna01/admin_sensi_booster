import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════
// TOUCH POINT MODEL
// ═══════════════════════════════════════════════
class _TouchPoint {
  int x; // Screen pixel X
  int y; // Screen pixel Y
  _TouchPoint({required this.x, required this.y});
}

// ═══════════════════════════════════════════════
// MAIN AUTO CLICKER PAGE
// ═══════════════════════════════════════════════
class AutoClickerPage extends StatefulWidget {
  const AutoClickerPage({super.key});

  @override
  State<AutoClickerPage> createState() => _AutoClickerPageState();
}

class _AutoClickerPageState extends State<AutoClickerPage> {
  static const MethodChannel _channel =
      MethodChannel('com.mfw.sensi_booster/autoclicker');
  static const MethodChannel _shizukuChannel =
      MethodChannel('com.mfw.sensi_booster/shizuku');
  static const MethodChannel _macroShizukuChannel =
      MethodChannel('com.mfw.sensi_booster/macro_shizuku');

  bool _isRunning = false;
  bool _isLoading = false;
  bool _serviceEnabled = false;
  bool _isShizukuMode = false;
  String _shizukuStatus = "loading";
  Timer? _shizukuTimer;
  int _cps = 10;

  final List<_TouchPoint> _touchPoints = [
    _TouchPoint(x: 540, y: 960),
  ];

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _checkShizukuStatus();
    _shizukuTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkShizukuStatus());
  }

  @override
  void dispose() {
    _shizukuTimer?.cancel();
    super.dispose();
  }

  // ── Native bridge helpers ──────────────────

  Future<void> _checkShizukuStatus() async {
    try {
      final status = await _shizukuChannel.invokeMethod('checkShizukuStatus');
      if (mounted && status != null) {
        setState(() => _shizukuStatus = status as String);
        if (_shizukuStatus == "running_granted" && _isShizukuMode) {
          await _macroShizukuChannel.invokeMethod('bindService');
        }
      }
    } catch (_) {}
  }

  Future<void> _checkServiceStatus() async {
    try {
      final bool enabled =
          await _channel.invokeMethod('isEnabled') ?? false;
      final bool running =
          await _channel.invokeMethod('isRunning') ?? false;
      if (mounted) {
        setState(() {
          _serviceEnabled = enabled;
          _isRunning = running;
        });
      }
    } catch (_) {}
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openSettings');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _checkServiceStatus();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _startClicker() async {
    // Re-check service status first
    await _checkServiceStatus();

    if (!_serviceEnabled) {
      _openAccessibilitySettings();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final intervalMs = (1000 / _cps).round();
      final xList = _touchPoints.map((p) => p.x.toDouble()).toList();
      final yList = _touchPoints.map((p) => p.y.toDouble()).toList();

      final success = await _channel.invokeMethod('start', {
        'interval': intervalMs,
        'xList': xList,
        'yList': yList,
      }) ?? false;

      if (mounted) {
        setState(() {
          _isRunning = success;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? "Auto Clicker Active! $_cps CPS, ${_touchPoints.length} point(s)"
                  : "Service not connected. Enable accessibility first.",
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor:
                success ? AppColors.neonGreenDark : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _stopClicker() async {
    setState(() => _isLoading = true);
    try {
      await _channel.invokeMethod('stop');
      if (mounted) {
        setState(() {
          _isRunning = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Auto Clicker stopped",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.card,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Touch point management ─────────────────

  void _addTouchPoint() {
    if (_touchPoints.length >= 10) return;
    final ratio = MediaQuery.of(context).devicePixelRatio;
    final sw = (MediaQuery.of(context).size.width * ratio).toInt();
    final sh = (MediaQuery.of(context).size.height * ratio).toInt();
    final i = _touchPoints.length;
    final x = (sw ~/ 4) + ((i % 3) * (sw ~/ 4));
    final y = (sh ~/ 3) + ((i ~/ 3) * (sh ~/ 4));
    setState(() {
      _touchPoints.add(_TouchPoint(
        x: x.clamp(100, sw - 100),
        y: y.clamp(100, sh - 100),
      ));
    });
  }

  void _removeTouchPoint() {
    if (_touchPoints.length <= 1) return;
    setState(() => _touchPoints.removeLast());
  }

  // ── Key Map Screen ─────────────────────────

  Future<void> _openKeyMapScreen() async {
    final result = await Navigator.push<List<_TouchPoint>>(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _KeyMapScreen(
          touchPoints: _touchPoints
              .map((p) => _TouchPoint(x: p.x, y: p.y))
              .toList(),
          maxPoints: 10,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _touchPoints
          ..clear()
          ..addAll(result);
      });
    }
  }

  // ── Floating Overlay ───────────────────────

  Future<void> _launchFloatingOverlay() async {
    try {
      final bool hasPerm =
          await _channel.invokeMethod('checkOverlayPermission') ?? false;
      if (!hasPerm) {
        await _channel.invokeMethod('requestOverlayPermission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Overlay permission needed",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }

      final intervalMs = (1000 / _cps).round();
      await _channel.invokeMethod('startAutoClickerOverlay', {
        'interval': intervalMs,
        'cps': _cps,
        'pointCount': _touchPoints.length,
        'xList': _touchPoints.map((p) => p.x.toDouble()).toList(),
        'yList': _touchPoints.map((p) => p.y.toDouble()).toList(),
        'isShizukuMode': _isShizukuMode,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Floating panel active!",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.neonGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonGreen, size: 18),
          onPressed: () async {
            if (_isRunning) await _stopClicker();
            if (mounted) Navigator.pop(context, _isRunning);
          },
        ),
        title: Text("MACRO AUTO CLICKER",
            style: GoogleFonts.inter(
                color: AppColors.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        actions: [
          if (_isRunning) _buildRunningBadge(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceStatus(),
            const SizedBox(height: 20),
            _buildSectionTitle("CLICK SPEED", Icons.speed_rounded),
            const SizedBox(height: 10),
            _buildSpeedControl(),
            const SizedBox(height: 24),
            _buildSectionTitle("TOUCH POINTS", Icons.gps_fixed_rounded),
            const SizedBox(height: 6),
            Text(
              "${_touchPoints.length} point(s) configured",
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 10),
            _buildTouchPointCounter(),
            const SizedBox(height: 16),
            _buildSectionTitle("KEY MAP", Icons.map_outlined),
            const SizedBox(height: 10),
            _buildKeyMapPreview(),
            const SizedBox(height: 12),
            _buildOpenKeyMapButton(),
            const SizedBox(height: 16),
            _buildPointDetailsList(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 12),
            _buildLaunchOverlayButton(),
            const SizedBox(height: 20),
            _buildTipCard(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // WIDGET BUILDERS
  // ═══════════════════════════════════════════

  Widget _buildRunningBadge() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.redAccent.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                      color: Colors.redAccent.withAlpha(127),
                      blurRadius: 4)
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text("RUNNING",
                style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatus() {
    return Column(
      children: [
        // Mode Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isShizukuMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isShizukuMode
                          ? AppColors.neonGreen.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Accessibility Mode",
                      style: GoogleFonts.inter(
                        color: !_isShizukuMode
                            ? AppColors.neonGreen
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isShizukuMode = true;
                    _checkShizukuStatus();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isShizukuMode
                          ? AppColors.neonGreen.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Shizuku Mode",
                      style: GoogleFonts.inter(
                        color: _isShizukuMode
                            ? AppColors.neonGreen
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Status Indicator
        _isShizukuMode
            ? _buildShizukuStatus()
            : GestureDetector(
                onTap: _openAccessibilitySettings,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _serviceEnabled
                        ? AppColors.neonGreen.withAlpha(15)
                        : Colors.orange.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _serviceEnabled
                          ? AppColors.neonGreen.withAlpha(76)
                          : Colors.orange.withAlpha(76),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _serviceEnabled
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: _serviceEnabled
                            ? AppColors.neonGreen
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _serviceEnabled
                                  ? "Accessibility Service Enabled"
                                  : "Accessibility Service Required",
                              style: GoogleFonts.inter(
                                color: _serviceEnabled
                                    ? AppColors.neonGreen
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _serviceEnabled
                                  ? "Tap to manage settings"
                                  : "Tap to open Settings and enable it",
                              style: GoogleFonts.inter(
                                  color: AppColors.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildShizukuStatus() {
    bool isGranted = _shizukuStatus == "running_granted";
    bool notGranted = _shizukuStatus == "running_not_granted";
    
    Color color = isGranted
        ? AppColors.neonGreen
        : notGranted ? Colors.orange : Colors.redAccent;
        
    String title = isGranted
        ? "Shizuku Service Running & Granted"
        : notGranted
            ? "Shizuku Running but Not Granted"
            : "Shizuku Not Running";
            
    String sub = isGranted
        ? "Multi-Touch Macro is ready"
        : notGranted
            ? "Please grant permission in Shizuku app"
            : "Please start Shizuku daemon first";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 6),
        Text(title,
            style: GoogleFonts.inter(
                color: AppColors.textWhite,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildSpeedControl() {
    final interval = (1000 / _cps).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.neonGreen.withAlpha(50)),
            ),
            child: Column(
              children: [
                Text("$_cps",
                    style: GoogleFonts.orbitron(
                        color: AppColors.neonGreen,
                        fontSize: 36,
                        fontWeight: FontWeight.w800)),
                Text("CLICKS / SECOND",
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
                Text("Interval: ${interval}ms",
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCounterButton(Icons.remove, () {
                if (_cps > 1) setState(() => _cps--);
              }),
              Expanded(
                child: Slider(
                  value: _cps.toDouble(),
                  min: 1,
                  max: 100,
                  activeColor: AppColors.neonGreen,
                  inactiveColor: AppColors.border,
                  onChanged: (val) =>
                      setState(() => _cps = val.round()),
                ),
              ),
              _buildCounterButton(Icons.add, () {
                if (_cps < 100) setState(() => _cps++);
              }),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [5, 10, 20, 50].map((v) {
              final sel = _cps == v;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _cps = v),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 3),
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.neonGreen.withAlpha(30)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: sel
                            ? AppColors.neonGreen.withAlpha(127)
                            : AppColors.border,
                      ),
                    ),
                    child: Text("${v}x",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: sel
                                ? AppColors.neonGreen
                                : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchPointCounter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Number of Points",
                  style: GoogleFonts.inter(
                      color: AppColors.textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text("Multi-target disabled for now",
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w400)),
            ],
          ),
          Container(
            width: 44,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.neonGreen.withAlpha(76)),
            ),
            child: Text("1",
                style: GoogleFonts.orbitron(
                    color: AppColors.neonGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Key Map Preview (mini screen with points) ──

  Widget _buildKeyMapPreview() {
    final ratio = MediaQuery.of(context).devicePixelRatio;
    final screenPxW =
        (MediaQuery.of(context).size.width * ratio).roundToDouble();
    final screenPxH =
        (MediaQuery.of(context).size.height * ratio).roundToDouble();

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
            // Label
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("SCREEN MAP",
                    style: GoogleFonts.inter(
                        color: AppColors.neonGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
            ),
            // Touch points mapped to preview
            LayoutBuilder(
              builder: (context, constraints) {
                final pw = constraints.maxWidth;
                final ph = constraints.maxHeight;
                final scaleX = pw / screenPxW;
                final scaleY = ph / screenPxH;

                return Stack(
                  children: _touchPoints.asMap().entries.map((e) {
                    final i = e.key;
                    final pt = e.value;
                    final dx =
                        (pt.x * scaleX).clamp(8.0, pw - 8.0);
                    final dy =
                        (pt.y * scaleY).clamp(8.0, ph - 8.0);

                    return Positioned(
                      left: dx - 12,
                      top: dy - 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColors.neonGreen.withAlpha(40),
                          border: Border.all(
                              color: AppColors.neonGreen,
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonGreen
                                  .withAlpha(80),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text("${i + 1}",
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenKeyMapButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openKeyMapScreen,
        icon: const Icon(Icons.fullscreen_rounded,
            color: Colors.black, size: 18),
        label: Text("OPEN FULLSCREEN KEY MAP",
            style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AppColors.neonGreen.withAlpha(80),
        ),
      ),
    );
  }

  // ── Point details (compact read-only list) ─

  Widget _buildPointDetailsList() {
    final ratio = MediaQuery.of(context).devicePixelRatio;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("POINT COORDINATES",
              style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          ..._touchPoints.asMap().entries.map((e) {
            final i = e.key;
            final pt = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                        child: Text("${i + 1}",
                            style: GoogleFonts.inter(
                                color: AppColors.neonGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "X: ${pt.x}px  Y: ${pt.y}px",
                    style: GoogleFonts.sourceCodePro(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    "(${(pt.x / ratio).round()}, ${(pt.y / ratio).round()}) dp",
                    style: GoogleFonts.sourceCodePro(
                        color: AppColors.textMuted.withAlpha(100),
                        fontSize: 9),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Action Buttons ─────────────────────────

  Widget _buildActionButtons() {
    if (_isRunning) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _stopClicker,
          icon: const Icon(Icons.stop_rounded,
              color: Colors.white, size: 18),
          label: Text(
            _isLoading ? "STOPPING..." : "STOP CLICKER",
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withAlpha(38),
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Colors.redAccent.withAlpha(100)),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _startClicker,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2))
            : const Icon(Icons.play_arrow_rounded,
                color: Colors.black, size: 20),
        label: Text(
          _isLoading
              ? "STARTING..."
              : (_serviceEnabled
                  ? "START CLICKER"
                  : "ENABLE & START"),
          style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          shadowColor: AppColors.neonGreen.withAlpha(76),
          elevation: 6,
        ),
      ),
    );
  }

  Widget _buildLaunchOverlayButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _launchFloatingOverlay,
        icon: const Icon(Icons.open_in_new_rounded,
            color: AppColors.neonGreen, size: 16),
        label: Text("LAUNCH SIDE PANEL",
            style: GoogleFonts.inter(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: AppColors.neonGreen.withAlpha(100)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.neonGreen.withAlpha(38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.neonGreen.withAlpha(178), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "1. Enable accessibility service\n"
              "2. Set click speed (CPS)\n"
              "3. Open Key Map to place touch points on screen\n"
              "4. Press START or launch floating panel\n\n"
              "Tap = add point  •  Drag = move  •  Long-press = remove",
              style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.neonGreen, size: 18),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FULLSCREEN KEY MAP PLACEMENT SCREEN
// ═══════════════════════════════════════════════
class _KeyMapScreen extends StatefulWidget {
  final List<_TouchPoint> touchPoints;
  final int maxPoints;

  const _KeyMapScreen({
    required this.touchPoints,
    required this.maxPoints,
  });

  @override
  State<_KeyMapScreen> createState() => _KeyMapScreenState();
}

class _KeyMapScreenState extends State<_KeyMapScreen>
    with SingleTickerProviderStateMixin {
  late List<_TouchPoint> _points;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _points = widget.touchPoints;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Go immersive for accurate coordinate mapping
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Restore normal UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _addPointAt(Offset logicalPos) {
    if (_points.length >= widget.maxPoints) return;
    final ratio = MediaQuery.of(context).devicePixelRatio;
    setState(() {
      _points.add(_TouchPoint(
        x: (logicalPos.dx * ratio).round(),
        y: (logicalPos.dy * ratio).round(),
      ));
    });
  }

  void _removePoint(int index) {
    if (_points.length <= 1) return;
    setState(() => _points.removeAt(index));
  }

  void _movePoint(int index, Offset delta) {
    final ratio = MediaQuery.of(context).devicePixelRatio;
    final screenPxW =
        (MediaQuery.of(context).size.width * ratio).round();
    final screenPxH =
        (MediaQuery.of(context).size.height * ratio).round();

    setState(() {
      _points[index].x =
          (_points[index].x + (delta.dx * ratio).round())
              .clamp(0, screenPxW);
      _points[index].y =
          (_points[index].y + (delta.dy * ratio).round())
              .clamp(0, screenPxH);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.of(context).devicePixelRatio;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Semi-transparent dark overlay
          Container(color: Colors.black.withAlpha(140)),

          // Tap anywhere to add point
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) =>
                _addPointAt(details.localPosition),
            child: const SizedBox.expand(),
          ),

          // Draggable touch points
          for (int i = 0; i < _points.length; i++)
            _buildDraggablePoint(i, ratio, screenW, screenH),

          // ── Top instruction bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(200),
                    Colors.black.withAlpha(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text("KEY MAP PLACEMENT",
                            style: GoogleFonts.orbitron(
                                color: AppColors.neonGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(
                          "Tap = Add point  •  Drag = Move  •  Long-press = Remove",
                          style: GoogleFonts.inter(
                              color: Colors.white.withAlpha(180),
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${_points.length}/${widget.maxPoints}",
                      style: GoogleFonts.orbitron(
                          color: AppColors.neonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom action bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewPadding.bottom + 12,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(220),
                    Colors.black.withAlpha(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white.withAlpha(60)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: Text("CANCEL",
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, _points),
                      icon: const Icon(Icons.check_rounded,
                          color: Colors.black, size: 18),
                      label: Text("CONFIRM PLACEMENT",
                          style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor:
                            AppColors.neonGreen.withAlpha(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePoint(
      int index, double ratio, double screenW, double screenH) {
    final pt = _points[index];
    final logicalX = pt.x / ratio;
    final logicalY = pt.y / ratio;
    const markerRadius = 22.0;

    return Positioned(
      left: logicalX - markerRadius,
      top: logicalY - markerRadius,
      child: GestureDetector(
        onPanUpdate: (details) =>
            _movePoint(index, details.delta),
        onLongPress: () => _removePoint(index),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = 1.0 + (_pulseController.value * 0.15);
            return SizedBox(
              width: markerRadius * 2,
              height: markerRadius * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: markerRadius * 2,
                      height: markerRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.neonGreen
                              .withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Inner solid circle
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonGreen.withAlpha(50),
                      border: Border.all(
                        color: AppColors.neonGreen,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.neonGreen.withAlpha(100),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // Crosshair lines
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 1,
                      height: 8,
                      color:
                          AppColors.neonGreen.withAlpha(120),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 1,
                      height: 8,
                      color:
                          AppColors.neonGreen.withAlpha(120),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 8,
                      height: 1,
                      color:
                          AppColors.neonGreen.withAlpha(120),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 1,
                      color:
                          AppColors.neonGreen.withAlpha(120),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// GRID PAINTER (for preview background)
// ═══════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted.withAlpha(15)
      ..style = PaintingStyle.fill;

    for (double x = 15; x < size.width; x += 15) {
      for (double y = 12; y < size.height; y += 12) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
