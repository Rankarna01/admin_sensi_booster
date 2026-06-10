import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';

class CrosshairSettingsPanel extends StatefulWidget {
  const CrosshairSettingsPanel({super.key});

  @override
  State<CrosshairSettingsPanel> createState() => _CrosshairSettingsPanelState();
}

class _CrosshairSettingsPanelState extends State<CrosshairSettingsPanel> {
  static const MethodChannel _channel = MethodChannel('com.mfw.sensi_booster/crosshair');

  // Default crosshair settings
  String _selectedShape = 'cross_dot';
  Color _selectedColor = const Color(0xFFFF0000);
  double _size = 40;
  double _opacity = 1.0; 
  int _offsetX = 0;
  int _offsetY = 0;

  final List<Map<String, dynamic>> _shapes = [
    {'id': 'cross_dot', 'label': 'Cross+Dot', 'icon': Icons.add_circle_outline},
    {'id': 'cross', 'label': 'Cross', 'icon': Icons.add},
    {'id': 'dot', 'label': 'Dot', 'icon': Icons.circle},
    {'id': 'circle', 'label': 'Circle', 'icon': Icons.circle_outlined},
    {'id': 't_shape', 'label': 'T-Shape', 'icon': Icons.text_fields},
    {'id': 'diamond', 'label': 'Diamond', 'icon': Icons.diamond_outlined},
  ];

  final List<Color> _presetColors = [
    const Color(0xFFFF0000), // Red
    const Color(0xFF00FF00), // Green
    const Color(0xFF007AFF), // Blue
    const Color(0xFFFFFF00), // Yellow
    const Color(0xFFFFFFFF), // White
    const Color(0xFFFF00FF), // Magenta
    const Color(0xFF00FFFF), // Cyan
    const Color(0xFFFF6600), // Orange
  ];

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Future<void> _updateCrosshair() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('updateCrosshair', {
        'shape': _selectedShape,
        'color': _colorToHex(_selectedColor),
        'size': _size.toInt(),
        'opacity': (_opacity * 255).toInt(),
        'offsetX': _offsetX,
        'offsetY': _offsetY,
      });
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PREVIEW
        _buildPreviewSection(),
        const SizedBox(height: 20),

        // SHAPE
        _buildSectionTitle("SHAPE", Icons.extension_outlined),
        const SizedBox(height: 10),
        _buildShapeSelector(),
        const SizedBox(height: 20),

        // COLOR
        _buildSectionTitle("COLOR", Icons.palette_outlined),
        const SizedBox(height: 10),
        _buildColorSelector(),
        const SizedBox(height: 20),

        // SIZE
        _buildSectionTitle("SIZE", Icons.straighten_outlined),
        _buildSlider(_size, 10, 100, (val) {
          setState(() => _size = val);
          _updateCrosshair();
        }),
        const SizedBox(height: 10),

        // OPACITY
        _buildSectionTitle("OPACITY", Icons.contrast_outlined),
        _buildSlider(_opacity * 100, 10, 100, (val) {
          setState(() => _opacity = val / 100);
          _updateCrosshair();
        }, unit: "%"),
        const SizedBox(height: 20),

        // POSITION (Compact D-Pad)
        _buildSectionTitle("POSITION", Icons.open_with_rounded),
        const SizedBox(height: 10),
        _buildCompactPositionControls(),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(
            child: CustomPaint(painter: _PreviewGridPainter()),
          ),
          Positioned(
            top: 8, left: 12,
            child: Text(
              "PREVIEW",
              style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.5),
            ),
          ),
          Center(
            child: CustomPaint(
              size: Size(_size * 1.5, _size * 1.5),
              painter: _CrosshairPreviewPainter(
                shape: _selectedShape,
                color: _selectedColor.withOpacity(_opacity),
              ),
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
        Text(title, style: GoogleFonts.orbitron(color: AppColors.textWhite, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildShapeSelector() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _shapes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final shape = _shapes[index];
          final isSelected = shape['id'] == _selectedShape;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedShape = shape['id']);
              _updateCrosshair();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonGreen.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppColors.neonGreen.withOpacity(0.5) : AppColors.border),
                boxShadow: isSelected ? AppColors.glowGreen(blur: 8, opacity: 0.05) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    shape['icon'] as IconData,
                    color: isSelected ? AppColors.neonGreen : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shape['label'] as String,
                    style: GoogleFonts.inter(
                      color: isSelected ? AppColors.neonGreen : AppColors.textMuted,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _presetColors.map((color) {
          final isSelected = color.value == _selectedColor.value;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedColor = color);
              _updateCrosshair();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)] : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlider(double value, double min, double max, ValueChanged<double> onChanged, {String unit = ""}) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.neonGreen,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            "${value.toInt()}$unit",
            textAlign: TextAlign.end,
            style: GoogleFonts.orbitron(color: AppColors.neonGreen, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPositionControls() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildAxisControl("X", _offsetX, (val) {
                setState(() => _offsetX = val);
                _updateCrosshair();
              }),
              _buildAxisControl("Y", _offsetY, (val) {
                setState(() => _offsetY = val);
                _updateCrosshair();
              }),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // D-Pad
        Column(
          children: [
            _buildDPadBtn(Icons.keyboard_arrow_up_rounded, () { setState(() => _offsetY -= 5); _updateCrosshair(); }),
            Row(
              children: [
                _buildDPadBtn(Icons.keyboard_arrow_left_rounded, () { setState(() => _offsetX -= 5); _updateCrosshair(); }),
                GestureDetector(
                  onTap: () { setState(() { _offsetX = 0; _offsetY = 0; }); _updateCrosshair(); },
                  child: Container(
                    width: 28, height: 28,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.neonGreen.withOpacity(0.3))),
                    child: const Icon(Icons.center_focus_strong_rounded, color: AppColors.neonGreen, size: 14),
                  ),
                ),
                _buildDPadBtn(Icons.keyboard_arrow_right_rounded, () { setState(() => _offsetX += 5); _updateCrosshair(); }),
              ],
            ),
            _buildDPadBtn(Icons.keyboard_arrow_down_rounded, () { setState(() => _offsetY += 5); _updateCrosshair(); }),
          ],
        )
      ],
    );
  }

  Widget _buildAxisControl(String axis, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Text(axis, style: GoogleFonts.orbitron(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: -300,
            max: 300,
            activeColor: AppColors.neonGreen,
            inactiveColor: AppColors.border,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        SizedBox(width: 30, child: Text("$value", textAlign: TextAlign.end, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 10, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildDPadBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
        child: Icon(icon, color: AppColors.textMuted, size: 16),
      ),
    );
  }
}

// Background Grid Pattern
class _PreviewGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;
    const double spacing = 15.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter
class _CrosshairPreviewPainter extends CustomPainter {
  final String shape;
  final Color color;

  _CrosshairPreviewPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..isAntiAlias = true..strokeCap = StrokeCap.round..style = PaintingStyle.fill..strokeWidth = size.width * 0.06;
    final outlinePaint = Paint()..color = color.withOpacity(0.3)..isAntiAlias = true..strokeCap = StrokeCap.round..style = PaintingStyle.fill..strokeWidth = size.width * 0.12;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.4;
    final gap = s * 0.2;

    switch (shape) {
      case 'dot':
        canvas.drawCircle(Offset(cx, cy), s * 0.12, paint);
        break;
      case 'cross':
        _drawCross(canvas, cx, cy, s, gap, paint, outlinePaint);
        break;
      case 'cross_dot':
        _drawCross(canvas, cx, cy, s, gap, paint, outlinePaint);
        canvas.drawCircle(Offset(cx, cy), s * 0.08, paint);
        break;
      case 'circle':
        final cPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = paint.strokeWidth;
        canvas.drawCircle(Offset(cx, cy), s * 0.35, cPaint);
        canvas.drawCircle(Offset(cx, cy), s * 0.06, paint);
        break;
      case 't_shape':
        canvas.drawLine(Offset(cx - s, cy - s * 0.3), Offset(cx + s, cy - s * 0.3), outlinePaint);
        canvas.drawLine(Offset(cx - s, cy - s * 0.3), Offset(cx + s, cy - s * 0.3), paint);
        canvas.drawLine(Offset(cx, cy - s * 0.3), Offset(cx, cy + s), outlinePaint);
        canvas.drawLine(Offset(cx, cy - s * 0.3), Offset(cx, cy + s), paint);
        canvas.drawCircle(Offset(cx, cy + s * 0.15), s * 0.06, paint);
        break;
      case 'diamond':
        final path = Path()..moveTo(cx, cy - s * 0.35)..lineTo(cx + s * 0.35, cy)..lineTo(cx, cy + s * 0.35)..lineTo(cx - s * 0.35, cy)..close();
        final sPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = paint.strokeWidth;
        canvas.drawPath(path, sPaint);
        canvas.drawCircle(Offset(cx, cy), s * 0.06, paint);
        break;
    }
  }

  void _drawCross(Canvas canvas, double cx, double cy, double s, double gap, Paint paint, Paint outlinePaint) {
    canvas.drawLine(Offset(cx, cy - s), Offset(cx, cy - gap), outlinePaint);
    canvas.drawLine(Offset(cx, cy - s), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + s), outlinePaint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + s), paint);
    canvas.drawLine(Offset(cx - s, cy), Offset(cx - gap, cy), outlinePaint);
    canvas.drawLine(Offset(cx - s, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + s, cy), outlinePaint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + s, cy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
