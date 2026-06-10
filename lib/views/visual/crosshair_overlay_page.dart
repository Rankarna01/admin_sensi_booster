import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Crosshair Overlay customization page.
/// Allows user to select shape, color, size, opacity, position
/// and activate the native overlay on top of games.
class CrosshairOverlayPage extends StatefulWidget {
  const CrosshairOverlayPage({super.key});

  @override
  State<CrosshairOverlayPage> createState() => _CrosshairOverlayPageState();
}

class _CrosshairOverlayPageState extends State<CrosshairOverlayPage> {
  static const MethodChannel _channel = MethodChannel('com.mfw.sensi_booster/crosshair');

  // Crosshair settings
  String _selectedShape = 'cross_dot';
  Color _selectedColor = const Color(0xFFFF0000);
  double _size = 40;
  double _opacity = 1.0; // 0.0 - 1.0
  int _offsetX = 0;
  int _offsetY = 0;
  bool _isActive = false;
  bool _isLoading = false;

  // Available shapes
  final List<Map<String, dynamic>> _shapes = [
    {'id': 'cross_dot', 'label': 'Cross + Dot', 'icon': Icons.add_circle_outline},
    {'id': 'cross', 'label': 'Cross', 'icon': Icons.add},
    {'id': 'dot', 'label': 'Dot', 'icon': Icons.circle},
    {'id': 'circle', 'label': 'Circle', 'icon': Icons.circle_outlined},
    {'id': 't_shape', 'label': 'T-Shape', 'icon': Icons.text_fields},
    {'id': 'diamond', 'label': 'Diamond', 'icon': Icons.diamond_outlined},
    {'id': 'plus_circle', 'label': 'Plus Circle', 'icon': Icons.add_circle},
    {'id': 'scope', 'label': 'Scope', 'icon': Icons.gps_fixed},
  ];

  // Preset colors
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

  Future<void> _startCrosshair() async {
    setState(() { _isLoading = true; });
    try {
      // Check overlay permission first
      final bool hasPerm = await _channel.invokeMethod('checkPermission') ?? false;
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Overlay permission needed", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              backgroundColor: Colors.orange,
            ),
          );
        }
        await _channel.invokeMethod('requestPermission');
        setState(() { _isLoading = false; });
        return;
      }

      await _channel.invokeMethod('startCrosshair', {
        'shape': _selectedShape,
        'color': _colorToHex(_selectedColor),
        'size': _size.toInt(),
        'opacity': (_opacity * 255).toInt(),
        'offsetX': _offsetX,
        'offsetY': _offsetY,
      });

      setState(() {
        _isActive = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Crosshair Active! Double-tap to toggle.", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.neonGreenDark,
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

  Future<void> _updateCrosshair() async {
    if (!_isActive) return;
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

  Future<void> _stopCrosshair() async {
    try {
      await _channel.invokeMethod('stopCrosshair');
      setState(() { _isActive = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Crosshair stopped", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.card,
          ),
        );
      }
    } catch (e) {
      debugPrint("Stop error: $e");
    }
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
          onPressed: () {
            // Return whether crosshair was active (don't stop it - it stays running)
            Navigator.pop(context, _isActive);
          },
        ),
        title: Text(
          "CROSSHAIR OVERLAY",
          style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        actions: [
          // Active indicator
          if (_isActive)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonGreen,
                        boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("LIVE", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 9, fontWeight: FontWeight.w700)),
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
            // PREVIEW
            _buildPreviewSection(),
            const SizedBox(height: 24),

            // SHAPE SELECTION
            _buildSectionTitle("SHAPE", Icons.extension_outlined),
            const SizedBox(height: 10),
            _buildShapeSelector(),
            const SizedBox(height: 24),

            // COLOR SELECTION
            _buildSectionTitle("COLOR", Icons.palette_outlined),
            const SizedBox(height: 10),
            _buildColorSelector(),
            const SizedBox(height: 24),

            // SIZE SLIDER
            _buildSectionTitle("SIZE", Icons.straighten_outlined),
            const SizedBox(height: 8),
            _buildSizeSlider(),
            const SizedBox(height: 24),

            // OPACITY SLIDER
            _buildSectionTitle("OPACITY", Icons.contrast_outlined),
            const SizedBox(height: 8),
            _buildOpacitySlider(),
            const SizedBox(height: 24),

            // POSITION
            _buildSectionTitle("POSITION", Icons.open_with_rounded),
            const SizedBox(height: 10),
            _buildPositionControls(),
            const SizedBox(height: 30),

            // ACTION BUTTONS
            _buildActionButtons(),
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
                      "Double-tap the crosshair while playing to toggle it on/off without leaving the game.",
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

  // === PREVIEW ===
  Widget _buildPreviewSection() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.neonGreen.withOpacity(0.03), blurRadius: 20),
          ...AppColors.cardShadow(),
        ],
      ),
      child: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(painter: _PreviewGridPainter()),
            ),
          ),
          // Center label
          Positioned(
            top: 10, left: 14,
            child: Text(
              "PREVIEW",
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
          ),
          // Crosshair preview
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

  // === SHAPE SELECTOR ===
  Widget _buildShapeSelector() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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
              duration: const Duration(milliseconds: 250),
              width: 64,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonGreen.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.neonGreen.withOpacity(0.5) : AppColors.border,
                ),
                boxShadow: isSelected ? AppColors.glowGreen(blur: 10, opacity: 0.08) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    shape['icon'] as IconData,
                    color: isSelected ? AppColors.neonGreen : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shape['label'] as String,
                    style: GoogleFonts.inter(
                      color: isSelected ? AppColors.neonGreen : AppColors.textMuted,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // === COLOR SELECTOR ===
  Widget _buildColorSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._presetColors.map((color) {
            final isSelected = color.value == _selectedColor.value;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                _updateCrosshair();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 10),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)]
                      : null,
                ),
              ),
            );
          }),
          // Custom color button
          GestureDetector(
            onTap: () => _showCustomColorPicker(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
                ),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomColorPicker() {
    Color tempColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text("Custom Color", style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: tempColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              ),
              const SizedBox(height: 16),
              _buildColorSlider("R", Colors.red, tempColor.red / 255, (v) {
                setDialogState(() => tempColor = Color.fromARGB(tempColor.alpha, (v * 255).toInt(), tempColor.green, tempColor.blue));
              }),
              _buildColorSlider("G", Colors.green, tempColor.green / 255, (v) {
                setDialogState(() => tempColor = Color.fromARGB(tempColor.alpha, tempColor.red, (v * 255).toInt(), tempColor.blue));
              }),
              _buildColorSlider("B", Colors.blue, tempColor.blue / 255, (v) {
                setDialogState(() => tempColor = Color.fromARGB(tempColor.alpha, tempColor.red, tempColor.green, (v * 255).toInt()));
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedColor = tempColor);
              _updateCrosshair();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen),
            child: Text("Apply", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSlider(String label, Color color, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Expanded(
          child: Slider(
            value: value,
            activeColor: color,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ),
        Text("${(value * 255).toInt()}", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  // === SIZE SLIDER ===
  Widget _buildSizeSlider() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _size,
            min: 10,
            max: 100,
            activeColor: AppColors.neonGreen,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              setState(() => _size = val);
              _updateCrosshair();
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
          child: Text("${_size.toInt()}", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // === OPACITY SLIDER ===
  Widget _buildOpacitySlider() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _opacity,
            min: 0.1,
            max: 1.0,
            activeColor: AppColors.neonGreen,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              setState(() => _opacity = val);
              _updateCrosshair();
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
          child: Text("${(_opacity * 100).toInt()}%", style: GoogleFonts.inter(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // === POSITION CONTROLS ===
  Widget _buildPositionControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // X Offset
          Row(
            children: [
              Text("X", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _offsetX.toDouble(),
                  min: -200,
                  max: 200,
                  activeColor: AppColors.neonGreen,
                  inactiveColor: AppColors.border,
                  onChanged: (val) {
                    setState(() => _offsetX = val.toInt());
                    _updateCrosshair();
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text("$_offsetX", textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Y Offset
          Row(
            children: [
              Text("Y", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _offsetY.toDouble(),
                  min: -300,
                  max: 300,
                  activeColor: AppColors.neonGreen,
                  inactiveColor: AppColors.border,
                  onChanged: (val) {
                    setState(() => _offsetY = val.toInt());
                    _updateCrosshair();
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text("$_offsetY", textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // D-Pad
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left
              _buildDPadButton(Icons.keyboard_arrow_left_rounded, () {
                setState(() => _offsetX -= 5);
                _updateCrosshair();
              }),
              Column(
                children: [
                  // Up
                  _buildDPadButton(Icons.keyboard_arrow_up_rounded, () {
                    setState(() => _offsetY -= 5);
                    _updateCrosshair();
                  }),
                  // Center reset
                  GestureDetector(
                    onTap: () {
                      setState(() { _offsetX = 0; _offsetY = 0; });
                      _updateCrosshair();
                    },
                    child: Container(
                      width: 36, height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.center_focus_strong_rounded, color: AppColors.neonGreen, size: 16),
                    ),
                  ),
                  // Down
                  _buildDPadButton(Icons.keyboard_arrow_down_rounded, () {
                    setState(() => _offsetY += 5);
                    _updateCrosshair();
                  }),
                ],
              ),
              // Right
              _buildDPadButton(Icons.keyboard_arrow_right_rounded, () {
                setState(() => _offsetX += 5);
                _updateCrosshair();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textMuted, size: 18),
      ),
    );
  }

  // === ACTION BUTTONS ===
  Widget _buildActionButtons() {
    if (_isActive) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _stopCrosshair,
              icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 16),
              label: Text("STOP", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.15),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _startCrosshair,
        icon: _isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
        label: Text(
          _isLoading ? "STARTING..." : "ACTIVATE CROSSHAIR",
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: AppColors.neonGreen.withOpacity(0.3),
          elevation: 6,
        ),
      ),
    );
  }
}

// === CROSSHAIR PREVIEW PAINTER ===
class _CrosshairPreviewPainter extends CustomPainter {
  final String shape;
  final Color color;

  _CrosshairPreviewPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = size.width * 0.06;

    final outlinePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = size.width * 0.12;

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
        final path = Path()
          ..moveTo(cx, cy - s * 0.35)
          ..lineTo(cx + s * 0.35, cy)
          ..lineTo(cx, cy + s * 0.35)
          ..lineTo(cx - s * 0.35, cy)
          ..close();
        final sPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = paint.strokeWidth;
        canvas.drawPath(path, sPaint);
        canvas.drawCircle(Offset(cx, cy), s * 0.06, paint);
        break;
      case 'plus_circle':
        final cPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = paint.strokeWidth;
        canvas.drawCircle(Offset(cx, cy), s * 0.3, cPaint);
        final inner = s * 0.15;
        canvas.drawLine(Offset(cx - inner, cy), Offset(cx + inner, cy), paint);
        canvas.drawLine(Offset(cx, cy - inner), Offset(cx, cy + inner), paint);
        canvas.drawCircle(Offset(cx, cy), s * 0.04, paint);
        break;
      case 'scope':
        final cPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = paint.strokeWidth;
        final r = s * 0.4;
        canvas.drawCircle(Offset(cx, cy), r, cPaint);
        final tg = r * 0.35;
        canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy - r + tg), paint);
        canvas.drawLine(Offset(cx, cy + r), Offset(cx, cy + r - tg), paint);
        canvas.drawLine(Offset(cx - r, cy), Offset(cx - r + tg, cy), paint);
        canvas.drawLine(Offset(cx + r, cy), Offset(cx + r - tg, cy), paint);
        canvas.drawCircle(Offset(cx, cy), s * 0.04, paint);
        break;
    }
  }

  void _drawCross(Canvas canvas, double cx, double cy, double s, double gap, Paint paint, Paint outline) {
    canvas.drawLine(Offset(cx - s, cy), Offset(cx - gap, cy), outline);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + s, cy), outline);
    canvas.drawLine(Offset(cx, cy - s), Offset(cx, cy - gap), outline);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + s), outline);
    canvas.drawLine(Offset(cx - s, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + s, cy), paint);
    canvas.drawLine(Offset(cx, cy - s), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + s), paint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPreviewPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}

// === PREVIEW GRID PAINTER ===
class _PreviewGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.04)
      ..strokeWidth = 1;
    const spacing = 20.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
