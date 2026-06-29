import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A repeating, diagonal, semi-transparent text watermark painted over [child].
///
/// Used to discourage copying/screenshotting of design preview images on the
/// detail gallery and the full-screen viewer. The overlay is non-interactive —
/// taps pass straight through to the child below it.
class WatermarkOverlay extends StatelessWidget {
  final Widget child;
  final String text;

  /// Light fill tone of the watermark text. A dark outline is drawn underneath
  /// automatically, so the watermark stays legible on both light (white design
  /// previews) and dark (full-screen viewer) backgrounds.
  final Color color;
  final double fontSize;
  final double opacity;

  const WatermarkOverlay({
    super.key,
    required this.child,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 16,
    this.opacity = 0.28,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _WatermarkPainter(
                text: text,
                fillColor: color.withValues(alpha: opacity),
                outlineColor: Colors.black.withValues(alpha: opacity * 0.7),
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  final String text;
  final Color fillColor;
  final Color outlineColor;
  final double fontSize;

  _WatermarkPainter({
    required this.text,
    required this.fillColor,
    required this.outlineColor,
    required this.fontSize,
  });

  TextPainter _painter({required bool outline}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          // Outline pass paints a thin dark stroke; fill pass paints the light
          // body on top. Together they read on any underlying image colour.
          foreground: outline
              ? (Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.4
                ..color = outlineColor)
              : (Paint()..color = fillColor),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final stroke = _painter(outline: true);
    final fill = _painter(outline: false);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Rotate the canvas around its centre so the tiled text runs diagonally.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6); // -30 degrees
    canvas.translate(-size.width / 2, -size.height / 2);

    final stepX = fill.width + 48;
    final stepY = fill.height + 56;
    // Overscan well past the bounds so rotated corners stay covered.
    for (double y = -size.height; y < size.height * 2; y += stepY) {
      for (double x = -size.width; x < size.width * 2; x += stepX) {
        final offset = Offset(x, y);
        stroke.paint(canvas, offset);
        fill.paint(canvas, offset);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter old) =>
      old.text != text ||
      old.fillColor != fillColor ||
      old.outlineColor != outlineColor ||
      old.fontSize != fontSize;
}
