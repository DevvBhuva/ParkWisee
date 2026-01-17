import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlideToBookButton extends StatefulWidget {
  final VoidCallback onCompleted;
  final String label;
  final String completionLabel;

  const SlideToBookButton({
    Key? key,
    required this.onCompleted,
    this.label = 'Book Spot',
    this.completionLabel = 'BOOKED',
  }) : super(key: key);

  @override
  State<SlideToBookButton> createState() => _SlideToBookButtonState();
}

class _SlideToBookButtonState extends State<SlideToBookButton> {
  double _dragValue = 0.0;
  bool _isCompleted = false;
  final double _padding = 4.0;
  final double _knobSize = 48.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isCompleted) return;

    final maxDrag = maxWidth - _knobSize - (_padding * 2);
    double newValue = _dragValue + (details.delta.dx / maxDrag);

    setState(() {
      _dragValue = newValue.clamp(0.0, 1.0);
    });

    if (_dragValue >= 0.98) {
      setState(() {
        _isCompleted = true;
        _dragValue = 1.0;
      });
      widget.onCompleted();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isCompleted) return;

    // Snap back if not completed
    if (_dragValue < 0.98) {
      setState(() {
        _dragValue = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxDrag = maxWidth - _knobSize - (_padding * 2);

        // Color transition logic
        // User asked: "when arrow reached right... changes to green"
        // We can transition or just switch. Let's interpolate for a smooth feel.
        final bgColor = _isCompleted
            ? const Color(0xFF00C853) // Success Green
            : Color.lerp(Colors.black, const Color(0xFF00C853), _dragValue) ??
                  Colors.black;

        return Container(
          height: _knobSize + (_padding * 2),
          width: maxWidth,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              // Centered Text
              Center(
                child: Opacity(
                  opacity: 1.0 - _dragValue, // Fade out as we slide
                  child: Text(
                    widget.label, // "Slide to Book" (or customized)
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // Success Text (Visible only when completed)
              if (_isCompleted)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.completionLabel,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

              // Draggable Knob
              AnimatedPositioned(
                duration: const Duration(milliseconds: 50),
                left: _padding + (_dragValue * maxDrag),
                top: _padding,
                bottom: _padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onHorizontalDragUpdate(details, maxWidth),
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: Container(
                    width: _knobSize,
                    height: _knobSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _isCompleted
                          ? const Icon(Icons.check, color: Color(0xFF00C853))
                          : const Icon(
                              Icons.chevron_right,
                              color: Colors.black,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
