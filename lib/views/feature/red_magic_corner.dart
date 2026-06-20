import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────
// Data model for real device stats (via MethodChannel)
// ─────────────────────────────────────────────────────────
class DeviceStats {
  final double cpuPercent;   // 0–100
  final double ramUsedGB;
  final double ramTotalGB;
  final int    batteryPercent;
  final double tempCelsius;
  final int    fpsEstimate;

  const DeviceStats({
    this.cpuPercent   = 0,
    this.ramUsedGB    = 0,
    this.ramTotalGB   = 0,
    this.batteryPercent = 0,
    this.tempCelsius  = 0,
    this.fpsEstimate  = 60,
  });
}

// ─────────────────────────────────────────────────────────
// Feature definitions matching PackageModel keys
// ─────────────────────────────────────────────────────────
const List<Map<String, dynamic>> kAllFeatures = [
  {'key': 'floating_game',   'icon': FontAwesomeIcons.layerGroup,     'label': 'Floating',   'color': Color(0xFFFF4444)},
  {'key': 'crosshair',       'icon': FontAwesomeIcons.crosshairs,     'label': 'Crosshair',  'color': Color(0xFFFF6B00)},
  {'key': 'cpu_tweak',       'icon': FontAwesomeIcons.microchip,      'label': 'CPU Boost',  'color': Color(0xFFFF4444)},
  {'key': 'graphics_tweak',  'icon': FontAwesomeIcons.cogs,           'label': 'GPU Boost',  'color': Color(0xFFCC0000)},
  {'key': 'latency_mode',    'icon': FontAwesomeIcons.wifi,           'label': 'Low Ping',   'color': Color(0xFFFF4444)},
  {'key': 'speed_test',      'icon': FontAwesomeIcons.tachometerAlt,  'label': 'Speed',      'color': Color(0xFFFF6B00)},
  {'key': 'auto_clicker',    'icon': FontAwesomeIcons.bolt,           'label': 'AutoClick',  'color': Color(0xFFFF4444)},
  {'key': 'game_lab_sensi',  'icon': FontAwesomeIcons.gamepad,        'label': 'Sensi',      'color': Color(0xFFCC0000)},
  {'key': 'set_dpi',         'icon': FontAwesomeIcons.expandArrowsAlt,'label': 'DPI',        'color': Color(0xFFFF4444)},
  {'key': 'rog_monitor',     'icon': FontAwesomeIcons.chartBar,       'label': 'Monitor',    'color': Color(0xFFFF6B00)},
];

// ─────────────────────────────────────────────────────────
// Floating draggable launcher icon (shown in-game)
// ─────────────────────────────────────────────────────────
class RedMagicFloatingLauncher extends StatefulWidget {
  final Map<String, dynamic> features;
  final VoidCallback onDismiss;

  const RedMagicFloatingLauncher({
    super.key,
    required this.features,
    required this.onDismiss,
  });

  @override
  State<RedMagicFloatingLauncher> createState() => _RedMagicFloatingLauncherState();
}

class _RedMagicFloatingLauncherState extends State<RedMagicFloatingLauncher>
    with TickerProviderStateMixin {
  double _x = 20;
  double _y = 100;
  bool _showCorner = false;

  late AnimationController _breathController;
  late Animation<double>    _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Floating logo icon – draggable
        Positioned(
          left: _x,
          top:  _y,
          child: GestureDetector(
            onPanUpdate: (d) {
              setState(() {
                _x = (_x + d.delta.dx).clamp(0, size.width  - 60);
                _y = (_y + d.delta.dy).clamp(0, size.height - 60);
              });
            },
            onTap: () => setState(() => _showCorner = !_showCorner),
            child: AnimatedBuilder(
              animation: _breathAnim,
              builder: (_, __) => Transform.scale(
                scale: _breathAnim.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.7),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.8), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.red.withOpacity(0.4 * _breathAnim.value), blurRadius: 14, spreadRadius: 2),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.sports_esports, color: Colors.redAccent, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Game Corner Panel overlay
        if (_showCorner)
          RedMagicCornerPanel(
            features: widget.features,
            onClose: () => setState(() => _showCorner = false),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// The main Game Corner panel (ROG-style, red theme)
// ─────────────────────────────────────────────────────────
class RedMagicCornerPanel extends StatefulWidget {
  final Map<String, dynamic> features;
  final VoidCallback onClose;

  const RedMagicCornerPanel({
    super.key,
    required this.features,
    required this.onClose,
  });

  @override
  State<RedMagicCornerPanel> createState() => _RedMagicCornerPanelState();
}

class _RedMagicCornerPanelState extends State<RedMagicCornerPanel>
    with SingleTickerProviderStateMixin {
  static const _overlay = MethodChannel('com.mfw.sensi_booster/overlay');

  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;

  DeviceStats _stats = const DeviceStats();
  Timer? _statTimer;

  // Track which features are actively toggled on
  final Map<String, bool> _activeFeatures = {};

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();

    _fetchStats();
    _statTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchStats());
  }

  @override
  void dispose() {
    _statTimer?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final Map<dynamic, dynamic>? raw =
          await _overlay.invokeMethod('getDeviceStats');
      if (raw != null && mounted) {
        setState(() {
          _stats = DeviceStats(
            cpuPercent:      (raw['cpu']       ?? 0).toDouble(),
            ramUsedGB:       (raw['ramUsed']   ?? 0).toDouble(),
            ramTotalGB:      (raw['ramTotal']  ?? 0).toDouble(),
            batteryPercent:  (raw['battery']   ?? 0).toInt(),
            tempCelsius:     (raw['temp']      ?? 0).toDouble(),
            fpsEstimate:     (raw['fps']       ?? 60).toInt(),
          );
        });
      }
    } catch (_) {
      // Native not available → use animated mock
      if (mounted) {
        setState(() {
          final r = Random();
          _stats = DeviceStats(
            cpuPercent:     30 + r.nextDouble() * 50,
            ramUsedGB:      2.5 + r.nextDouble() * 2,
            ramTotalGB:     8,
            batteryPercent: 57,
            tempCelsius:    38 + r.nextDouble() * 10,
            fpsEstimate:    55 + r.nextInt(15),
          );
        });
      }
    }
  }

  void _closePanel() async {
    await _slideCtrl.reverse();
    widget.onClose();
  }

  // Get allowed features only
  List<Map<String, dynamic>> get _allowedFeatures => kAllFeatures
      .where((f) => widget.features[f['key']] == true)
      .toList();

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isLand = size.width > size.height;
    final sw     = isLand ? size.width : size.height;
    final sh     = isLand ? size.height : size.width;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dimmed backdrop
          GestureDetector(
            onTap: _closePanel,
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),

          // Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                width: sw * 0.96,
                height: sh * 0.55,
                margin: const EdgeInsets.only(bottom: 10),
                child: CustomPaint(
                  painter: _RedCornerPainter(
                    cpuPct: _stats.cpuPercent,
                    ramPct: _stats.ramTotalGB > 0
                        ? (_stats.ramUsedGB / _stats.ramTotalGB) * 100
                        : 0,
                  ),
                  child: _buildPanelContent(sw, sh),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent(double sw, double sh) {
    final panelH = sh * 0.55;
    final panelW = sw * 0.96;

    return SizedBox(
      width: panelW,
      height: panelH,
      child: Stack(
        children: [
          // ── TOP SPIKE label ──
          Positioned(
            top: panelH * 0.02,
            left: 0, right: 0,
            child: Center(
              child: Text(
                'GAME CORNER',
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),

          // ── CLOSE button ──
          Positioned(
            top: panelH * 0.25,
            left: panelW * 0.43,
            right: panelW * 0.43,
            child: GestureDetector(
              onTap: _closePanel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.redAccent, size: 18),
              ),
            ),
          ),

          // ── CENTER stats ──
          Positioned(
            top: panelH * 0.42,
            left: panelW * 0.35,
            right: panelW * 0.35,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('MFW SENSI', style: GoogleFonts.orbitron(
                  color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                _statRow(Icons.memory,             '${_stats.ramUsedGB.toStringAsFixed(1)}/${_stats.ramTotalGB.toStringAsFixed(0)} GB'),
                _statRow(Icons.thermostat_rounded,  '${_stats.tempCelsius.toStringAsFixed(1)}°C'),
                _statRow(Icons.battery_charging_full_rounded, '${_stats.batteryPercent}%'),
                _statRow(Icons.videogame_asset,     '${_stats.fpsEstimate} FPS'),
              ],
            ),
          ),

          // ── LEFT WING: 3 feature buttons ──
          Positioned(
            left: panelW * 0.04,
            top: panelH * 0.30,
            bottom: panelH * 0.05,
            width: panelW * 0.32,
            child: _buildFeatureGrid(_allowedFeatures.take(5).toList(), panelH),
          ),

          // ── RIGHT WING: 3 feature buttons ──
          Positioned(
            right: panelW * 0.04,
            top: panelH * 0.30,
            bottom: panelH * 0.05,
            width: panelW * 0.32,
            child: _buildFeatureGrid(_allowedFeatures.skip(5).take(5).toList(), panelH),
          ),

          // ── CPU label + bar (left edge) ──
          Positioned(
            left: panelW * 0.005,
            top: panelH * 0.30,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text('CPU  ${_stats.cpuPercent.toStringAsFixed(0)}%',
                style: GoogleFonts.orbitron(color: Colors.redAccent.withOpacity(0.8), fontSize: 8, letterSpacing: 1.5)),
            ),
          ),

          // ── RAM label + bar (right edge) ──
          Positioned(
            right: panelW * 0.005,
            top: panelH * 0.30,
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                'RAM  ${(_stats.ramTotalGB > 0 ? (_stats.ramUsedGB / _stats.ramTotalGB * 100) : 0).toStringAsFixed(0)}%',
                style: GoogleFonts.orbitron(color: Colors.redAccent.withOpacity(0.8), fontSize: 8, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.redAccent.withOpacity(0.7), size: 11),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(List<Map<String, dynamic>> feats, double panelH) {
    if (feats.isEmpty) {
      return Center(
        child: Text('—', style: TextStyle(color: Colors.white24, fontSize: 10)),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: feats.take(3).map(_buildFeatureBtn).toList(),
        ),
        const SizedBox(height: 10),
        if (feats.length > 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: feats.skip(3).take(2).map(_buildFeatureBtn).toList(),
          ),
      ],
    );
  }

  Widget _buildFeatureBtn(Map<String, dynamic> feat) {
    final key     = feat['key'] as String;
    final isOn    = _activeFeatures[key] ?? false;
    final color   = feat['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _activeFeatures[key] = !isOn),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isOn ? color.withOpacity(0.85) : Colors.white.withOpacity(0.15),
                width: isOn ? 1.5 : 1,
              ),
              boxShadow: isOn
                  ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: Center(
              child: FaIcon(
                feat['icon'] as FaIconData,
                color: isOn ? color : Colors.white38,
                size: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feat['label'] as String,
            style: GoogleFonts.inter(
              color: isOn ? color : Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Custom painter – ROG-style panel shape in RED
// ─────────────────────────────────────────────────────────
class _RedCornerPainter extends CustomPainter {
  final double cpuPct; // 0–100
  final double ramPct; // 0–100

  _RedCornerPainter({required this.cpuPct, required this.ramPct});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const wingTop = 0.25;
    const r = 18.0;

    // Main body path (same wing shape as GameCornerPainter)
    final body = Path()
      ..moveTo(w * 0.04 + r, h)
      ..quadraticBezierTo(w * 0.04, h, w * 0.04, h - r)
      ..lineTo(w * 0.12, h * wingTop)
      ..lineTo(w * 0.40, h * wingTop)
      ..lineTo(w * 0.43, 0)
      ..lineTo(w * 0.57, 0)
      ..lineTo(w * 0.60, h * wingTop)
      ..lineTo(w * 0.88, h * wingTop)
      ..lineTo(w * 0.96, h - r)
      ..quadraticBezierTo(w * 0.96, h, w * 0.96 - r, h)
      ..close();

    // Fill – very dark red background
    canvas.drawPath(body, Paint()..color = const Color(0xFF0D0000).withOpacity(0.95)..style = PaintingStyle.fill);

    // Glow stroke
    canvas.drawPath(body, Paint()
      ..color = Colors.red.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Solid border
    canvas.drawPath(body, Paint()
      ..color = Colors.redAccent.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Top spike fill (red)
    final spike = Path()
      ..moveTo(w * 0.40, h * wingTop)
      ..lineTo(w * 0.43, 0)
      ..lineTo(w * 0.57, 0)
      ..lineTo(w * 0.60, h * wingTop)
      ..close();
    canvas.drawPath(spike, Paint()..color = Colors.red..style = PaintingStyle.fill);

    // CPU blocks (left edge)
    _drawEdgeBlocks(canvas, w, h, wingTop, cpuPct, isLeft: true);
    // RAM blocks (right edge)
    _drawEdgeBlocks(canvas, w, h, wingTop, ramPct, isLeft: false);
  }

  void _drawEdgeBlocks(Canvas canvas, double w, double h, double wingTop,
      double percent, {required bool isLeft}) {
    const numBlocks = 6;
    final edgeH  = h * (1 - wingTop);
    final blkH   = (edgeH / numBlocks) - 3.0;
    final blkW   = w * 0.034;
    final active = ((percent / 100) * numBlocks).round().clamp(0, numBlocks);

    for (int i = 0; i < numBlocks; i++) {
      final yBot = h - i * (edgeH / numBlocks) - 1.5;
      final yTop = yBot - blkH;
      final tBot = (yBot - h * wingTop) / edgeH;
      final tTop = (yTop - h * wingTop) / edgeH;

      final Path blk;
      if (isLeft) {
        final xBot = w * (0.12 - 0.08 * tBot);
        final xTop = w * (0.12 - 0.08 * tTop);
        blk = Path()
          ..moveTo(xBot, yBot)..lineTo(xTop, yTop)
          ..lineTo(xTop + blkW, yTop)..lineTo(xBot + blkW, yBot)..close();
      } else {
        final xBot = w * (0.88 + 0.08 * tBot);
        final xTop = w * (0.88 + 0.08 * tTop);
        blk = Path()
          ..moveTo(xBot, yBot)..lineTo(xTop, yTop)
          ..lineTo(xTop - blkW, yTop)..lineTo(xBot - blkW, yBot)..close();
      }

      final isActive = i < active;
      canvas.drawPath(blk, Paint()
        ..color = (isActive ? Colors.red : Colors.red.withOpacity(0.12))
        ..style = PaintingStyle.fill);
      if (isActive) {
        canvas.drawPath(blk, Paint()
          ..color = Colors.red.withOpacity(0.35)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }
  }

  @override
  bool shouldRepaint(_RedCornerPainter old) =>
      old.cpuPct != cpuPct || old.ramPct != ramPct;
}
