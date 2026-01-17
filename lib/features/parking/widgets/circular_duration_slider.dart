import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CircularDurationSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final Color inactiveColor;

  const CircularDurationSlider({
    Key? key,
    required this.value,
    this.min = 0,
    this.max = 24,
    required this.onChanged,
    this.activeColor = const Color(0xFF00C853),
    this.inactiveColor = const Color(0xFFE0E0E0),
  }) : super(key: key);

  @override
  State<CircularDurationSlider> createState() => _CircularDurationSliderState();
}

class _CircularDurationSliderState extends State<CircularDurationSlider> {
  void _handlePan(Offset localPosition, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    Offset delta = localPosition - center;

    // Calculate angle in radians
    // 0 radians is at 3 o'clock.
    // We want our slider to start from somewhere appropriate.
    // Let's assume a standard clock-like or gauge interaction.
    // atan2 returns -pi to pi.
    double angle = atan2(delta.dy, delta.dx);

    // Normalize angle to 0 - 2pi
    if (angle < 0) {
      angle += 2 * pi;
    }

    // Map angle to value.
    // Let's say we want a 270 degree arc (3/4 circle), starting from 135 deg to 405 deg (bottom left to bottom right).
    // Or simple 360 for 24 hours.
    // User image showed "half-right" C-shape. That usually implies -90 to +90 or similar.
    // But 0-23 hours fits best on a full circle or 300 degree arc.
    // Let's do a 300 degree arc starting from -240 deg (approx 8 o'clock) to +60 deg (4 o'clock).
    // Actually, simpler 0 to 360 mapping might be intuitive for "hours".
    // Let's try 360 degree dial logic for 24 hours.

    // Shift so 0 is at top (-pi/2)
    double shiftedAngle = angle + pi / 2;
    if (shiftedAngle < 0) shiftedAngle += 2 * pi;
    if (shiftedAngle >= 2 * pi) shiftedAngle -= 2 * pi;

    // Calculate percentage
    double percentage = shiftedAngle / (2 * pi); // 0.0 to 1.0

    double rawValue = widget.min + (percentage * (widget.max - widget.min));

    // Snap to nearest 0.5 (30 mins)
    double snappedValue = (rawValue * 2).round() / 2.0;

    // Enforce 30 min minimum
    if (snappedValue < 0.5) snappedValue = 0.5;

    widget.onChanged(snappedValue.clamp(widget.min, widget.max));
  }

  String _formatDuration(double val) {
    int hours = val.floor();
    int minutes = ((val - hours) * 60).round();
    if (minutes == 60) {
      hours++;
      minutes = 0;
    }
    String label = '${hours}hr';
    if (minutes > 0) label += ' ${minutes}min';
    if (hours == 0 && minutes > 0) label = '${minutes}min';
    if (hours == 0 && minutes == 0) label = '0hr';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        _handlePan(box.globalToLocal(details.globalPosition), box.size);
      },
      onPanDown: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        _handlePan(box.globalToLocal(details.globalPosition), box.size);
      },
      child: CustomPaint(
        size: const Size(200, 200),
        painter: _CircularSliderPainter(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
        ),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(widget.value),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.activeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularSliderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final Color inactiveColor;

  _CircularSliderPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width, size.height) / 2 - 10;

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15;

    // Draw Background Circle/Arc
    // We use full circle for 0-24h clock feel
    paint.color = inactiveColor;
    canvas.drawCircle(center, radius, paint);

    // Draw Active Arc
    paint.color = activeColor;

    double percentage = (value - min) / (max - min);
    double sweepAngle = 2 * pi * percentage;

    // Start from top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );

    // Draw Knob
    double angle = -pi / 2 + sweepAngle;
    Offset knobPos = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    Paint knobPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Shadow for knob
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: knobPos, radius: 12)),
      Colors.black,
      4.0,
      true,
    );

    canvas.drawCircle(knobPos, 12, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularSliderPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
