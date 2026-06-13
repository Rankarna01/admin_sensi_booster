import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AutoClickerPage extends StatefulWidget {
  const AutoClickerPage({super.key});

  @override
  State<AutoClickerPage> createState() => _AutoClickerPageState();
}

class _AutoClickerPageState extends State<AutoClickerPage> {
  static const MethodChannel _channel = MethodChannel('com.mfw.sensi_booster/autoclicker');

  // State
  bool _isRunning = false;
  bool _isLoading = false;
  bool _serviceEnabled = false;

  // Speed: clicks per second (1-100)
  int _cps = 10;

  // Touch points: each has [x, y] coordinates
  final List<_TouchPoint> _touchPoints = [
    _TouchPoint(x: 540, y: 960),
  ];

  // Persistent controllers for coordinate inputs
  final List<TextEditingController> _xControllers = [];
  final List<TextEditingController> _yControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
    _checkServiceStatus();
  }

  @override
  void dispose() {
    for (final c in _xControllers) { c.dispose(); }
    for (final c in _yControllers) { c.dispose(); }
    super.dispose();
  }

  void _syncControllers() {
    while (_xControllers.length < _touchPoints.length) {
      _xControllers.add(TextEditingController());
      _yControllers.add(TextEditingController());
    }
    while (_xControllers.length > _touchPoints.length) {
      _xControllers.removeLast().dispose();
      _yControllers.removeLast().dispose();
    }
    for (int i = 0; i < _touchPoints.length; i++) {
      _xControllers[i].text = '${_touchPoints[i].x}';
      _yControllers[i].text = '${_touchPoints[i].y}';
    }
  }

  Future<void> _checkServiceStatus() async {
    try {
      final bool enabled = await _channel.invokeMethod('isEnabled') ?? false;
      final bool running = await _channel.invokeMethod('isRunning') ?? false;
      setState(() {
        _serviceEnabled = enabled;
        _isRunning = running;
      });
    } catch (_) {}
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openSettings');
      // Refresh status when user comes back
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _checkServiceStatus();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _startClicker() async {
    if (!_serviceEnabled) {
      _openAccessibilitySettings();
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final intervalMs = (1000 / _cps).round();
      final xList = _touchPoints.map((p) => p.x.toDouble()).toList();
      final yList = _touchPoints.map((p) => p.y.toDouble()).toList();

      final success = await _channel.invokeMethod('start', {
        'interval': intervalMs,
        'xList': xList,
        'yList': yList,
      }) ?? false;

      setState(() {
        _isRunning = success;
        _isLoading = false;
      });

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Auto Clicker Active! ${_cps} CPS, ${_touchPoints.length} point(s)", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.neonGreenDark,
          ),
        );
      } else if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Service not connected. Enable accessibility first.", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _stopClicker() async {
    setState(() { _isLoading = true; });
    try {
      await _channel.invokeMethod('stop');
      setState(() {
        _isRunning = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Auto Clicker stopped", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.card,
          ),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  void _addTouchPoint() {
    if (_touchPoints.length >= 10) return;
    final index = _touchPoints.length;
    final x = 200 + (index * 80) % 700;
    final y = 400 + (index * 120) % 1200;
    setState(() {
      _touchPoints.add(_TouchPoint(x: x, y: y));
      _syncControllers();
    });
  }

  void _removeTouchPoint() {
    if (_touchPoints.length <= 1) return;
    setState(() {
      _touchPoints.removeLast();
      _syncControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neonGreen, size: 18),
          onPressed: () async {
            if (_isRunning) await _stopClicker();
            if (mounted) Navigator.pop(context, _isRunning);
          },
        ),
        title: Text(
          "MACRO AUTO CLICKER",
          style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        actions: [
          if (_isRunning)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("RUNNING", style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACCESSIBILITY SERVICE STATUS
            _buildServiceStatus(),
            const SizedBox(height: 20),

            // SPEED CONTROL
            _buildSectionTitle("CLICK SPEED", Icons.speed_rounded),
            const SizedBox(height: 10),
            _buildSpeedControl(),
            const SizedBox(height: 24),

            // TOUCH POINTS
            _buildSectionTitle("TOUCH POINTS", Icons.gps_fixed_rounded),
            const SizedBox(height: 6),
            Text("${_touchPoints.length} point(s) configured", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 10),
            _buildTouchPointCounter(),
            const SizedBox(height: 12),
            _buildTouchPointsList(),
            const SizedBox(height: 24),

            // PREVIEW
            _buildSectionTitle("PREVIEW", Icons.visibility_outlined),
            const SizedBox(height: 10),
            _buildPreview(),
            const SizedBox(height: 30),

            // PLAY / STOP BUTTON
            _buildActionButtons(),
            const SizedBox(height: 12),

            // FLOATING OVERLAY BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _launchFloatingOverlay,
                icon: const Icon(Icons.open_in_new_rounded, color: AppColors.neonGreen, size: 16),
                label: Text("LAUNCH SIDE PANEL", style: GoogleFonts.inter(color: AppColors.neonGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.neonGreen.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TIP
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.neonGreen.withOpacity(0.7), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Enable the accessibility service first, then configure speed and touch points. The clicker will cycle through your touch points at the set speed.",
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === SERVICE STATUS ===
  Widget _buildServiceStatus() {
    return GestureDetector(
      onTap: _openAccessibilitySettings,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _serviceEnabled ? AppColors.neonGreen.withOpacity(0.06) : Colors.orange.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _serviceEnabled ? AppColors.neonGreen.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _serviceEnabled ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: _serviceEnabled ? AppColors.neonGreen : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _serviceEnabled ? "Accessibility Service Enabled" : "Accessibility Service Required",
                    style: GoogleFonts.inter(
                      color: _serviceEnabled ? AppColors.neonGreen : Colors.orange,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _serviceEnabled ? "Tap to manage settings" : "Tap to open Settings and enable it",
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  // === SECTION TITLE ===
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 6),
        Text(title, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      ],
    );
  }

  // === SPEED CONTROL ===
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
          // CPS display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text("$_cps", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 36, fontWeight: FontWeight.w800)),
                Text("CLICKS / SECOND", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                Text("Interval: ${interval}ms", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // +/- buttons with slider
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
                  onChanged: (val) => setState(() => _cps = val.round()),
                ),
              ),
              _buildCounterButton(Icons.add, () {
                if (_cps < 100) setState(() => _cps++);
              }),
            ],
          ),
          // Quick presets
          const SizedBox(height: 8),
          Row(
            children: [5, 10, 20, 50].map((v) {
              final isSelected = _cps == v;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _cps = v),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.neonGreen.withOpacity(0.12) : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSelected ? AppColors.neonGreen.withOpacity(0.5) : AppColors.border),
                    ),
                    child: Text("${v}x", textAlign: TextAlign.center, style: GoogleFonts.inter(color: isSelected ? AppColors.neonGreen : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // === TOUCH POINT COUNTER ===
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
          Text("Number of Points", style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600)),
          Row(
            children: [
              _buildCounterButton(Icons.remove, _removeTouchPoint),
              Container(
                width: 44, height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                ),
                child: Text("${_touchPoints.length}", style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              _buildCounterButton(Icons.add, _addTouchPoint),
            ],
          ),
        ],
      ),
    );
  }

  // === TOUCH POINTS LIST ===
  Widget _buildTouchPointsList() {
    return Column(
      children: _touchPoints.asMap().entries.map((entry) {
        final i = entry.key;
        final point = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(child: Text("${i + 1}", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 8),
                  Text("Point ${i + 1}", style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildCoordInput("X", i, true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCoordInput("Y", i, false)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoordInput(String label, int index, bool isX) {
    final controller = isX ? _xControllers[index] : _yControllers[index];
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.neonGreen), borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.surface,
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null) {
                setState(() {
                  if (isX) _touchPoints[index].x = parsed;
                  else _touchPoints[index].y = parsed;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // === PREVIEW ===
  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow(),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8, left: 12,
            child: Text("SCREEN MAP", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1)),
          ),
          Center(
            child: CustomPaint(
              size: const Size(200, 110),
              painter: _TouchPointPreviewPainter(points: _touchPoints),
            ),
          ),
        ],
      ),
    );
  }

  // === ACTION BUTTONS ===
  Widget _buildActionButtons() {
    if (_isRunning) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _stopClicker,
          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
          label: Text(_isLoading ? "STOPPING..." : "STOP CLICKER", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withOpacity(0.15),
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
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
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
        label: Text(
          _isLoading ? "STARTING..." : (_serviceEnabled ? "START CLICKER" : "ENABLE & START"),
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: AppColors.neonGreen.withOpacity(0.3),
          elevation: 6,
        ),
      ),
    );
  }

  // === LAUNCH FLOATING OVERLAY ===
  Future<void> _launchFloatingOverlay() async {
    try {
      // Check overlay permission
      final bool hasPerm = await _channel.invokeMethod('checkOverlayPermission') ?? false;
      if (!hasPerm) {
        await _channel.invokeMethod('requestOverlayPermission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Overlay permission needed", style: GoogleFonts.inter(fontWeight: FontWeight.w500)), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      final intervalMs = (1000 / _cps).round();
      final xList = _touchPoints.map((p) => p.x.toDouble()).toList();
      final yList = _touchPoints.map((p) => p.y.toDouble()).toList();

      await _channel.invokeMethod('startAutoClickerOverlay', {
        'interval': intervalMs,
        'cps': _cps,
        'pointCount': _touchPoints.length,
        'xList': xList,
        'yList': yList,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Floating panel active! Tap the side icon.", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.neonGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // === COUNTER BUTTON ===
  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
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

// === TOUCH POINT MODEL ===
class _TouchPoint {
  int x;
  int y;
  _TouchPoint({required this.x, required this.y});
}

// === TOUCH POINT PREVIEW PAINTER ===
class _TouchPointPreviewPainter extends CustomPainter {
  final List<_TouchPoint> points;

  _TouchPointPreviewPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw screen outline
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)), borderPaint);

    // Grid dots
    final gridPaint = Paint()..color = AppColors.textMuted.withOpacity(0.08)..style = PaintingStyle.fill;
    for (double gx = 20; gx < size.width; gx += 20) {
      for (double gy = 15; gy < size.height; gy += 15) {
        canvas.drawCircle(Offset(gx, gy), 0.5, gridPaint);
      }
    }

    // Draw touch points
    // Scale: assume 1080x1920 screen mapped to canvas size
    final scaleX = size.width / 1080;
    final scaleY = size.height / 1920;

    for (int i = 0; i < points.length; i++) {
      final px = points[i].x * scaleX;
      final py = points[i].y * scaleY;
      final clampedX = px.clamp(4.0, size.width - 4);
      final clampedY = py.clamp(4.0, size.height - 4);

      // Glow
      final glowPaint = Paint()
        ..color = AppColors.neonGreen.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(clampedX, clampedY), 8, glowPaint);

      // Point
      final pointPaint = Paint()
        ..color = AppColors.neonGreen
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(clampedX, clampedY), 3.5, pointPaint);

      // Number label
      final textPainter = TextPainter(
        text: TextSpan(
          text: "${i + 1}",
          style: GoogleFonts.inter(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(clampedX - textPainter.width / 2, clampedY + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _TouchPointPreviewPainter oldDelegate) => true;
}
