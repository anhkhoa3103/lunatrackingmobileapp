import 'package:flutter/material.dart';
import 'dart:math';

class OnboardingIllustration extends StatefulWidget {
  final int step; // 0, 1, 2
  const OnboardingIllustration({super.key, required this.step});

  @override
  State<OnboardingIllustration> createState() =>
      _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _float;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: 0, end: 12)
        .animate(CurvedAnimation(
            parent: _ctrl, curve: Curves.easeInOut));

    _rotate = Tween<double>(begin: -0.05, end: 0.05)
        .animate(CurvedAnimation(
            parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -_float.value),
        child: Transform.rotate(
          angle: _rotate.value,
          child: SizedBox(
            width: 240, height: 240,
            child: CustomPaint(
              painter: _IllustrationPainter(
                step: widget.step,
                progress: _ctrl.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final int step;
  final double progress;

  _IllustrationPainter({required this.step, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    switch (step) {
      case 0: _paintWelcome(canvas, size); break;
      case 1: _paintCycleInfo(canvas, size); break;
      case 2: _paintCalendar(canvas, size); break;
    }
  }

  // ── Step 0: Welcome — Moon with stars ────────────────────────
  void _paintWelcome(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const pink = Color(0xFFE05D6F);

    // Outer glow circle
    canvas.drawCircle(Offset(cx, cy), 100,
        Paint()..color = pink.withOpacity(0.08));
    canvas.drawCircle(Offset(cx, cy), 80,
        Paint()..color = pink.withOpacity(0.12));

    // Moon body
    canvas.drawCircle(Offset(cx, cy), 58,
        Paint()..color = pink);

    // Crescent shadow
    canvas.drawCircle(Offset(cx + 20, cy - 12), 46,
        Paint()..color = const Color(0xFFD4497A));

    // Inner highlight
    canvas.drawCircle(Offset(cx - 15, cy - 15), 15,
        Paint()..color = Colors.white.withOpacity(0.2));

    // Stars — animated with progress
    _drawAnimatedStar(canvas,
        Offset(cx + 75, cy - 55), 6, progress, pink);
    _drawAnimatedStar(canvas,
        Offset(cx - 70, cy - 45), 4, progress * 0.7, pink);
    _drawAnimatedStar(canvas,
        Offset(cx + 60, cy + 60), 5, progress * 0.85, pink);
    _drawAnimatedStar(canvas,
        Offset(cx - 80, cy + 40), 3, progress * 0.6, pink);
    _drawAnimatedStar(canvas,
        Offset(cx + 20, cy - 90), 4, progress * 0.9, pink);

    // Orbit dots
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi + progress * 0.5;
      canvas.drawCircle(
        Offset(cx + 95 * cos(angle), cy + 95 * sin(angle)),
        i % 3 == 0 ? 3.5 : 2,
        Paint()..color = pink.withOpacity(
            i % 3 == 0 ? 0.4 : 0.2),
      );
    }
  }

  // ── Step 1: Cycle info — Ring with phases ────────────────────
  void _paintCycleInfo(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    const phases = [
      Color(0xFFE05D6F),  // Menstrual
      Color(0xFFF5A623),  // Follicular
      Color(0xFF1D9E75),  // Ovulation
      Color(0xFF5B8CDE),  // Luteal
    ];

    // Background circle
    canvas.drawCircle(Offset(cx, cy), 95,
        Paint()..color = Colors.grey.withOpacity(0.08));

    // Phase arcs
    final rect = Rect.fromCircle(
        center: Offset(cx, cy), radius: 72);
    const sweepAngle = (2 * pi) / 4;
    for (var i = 0; i < 4; i++) {
      final startAngle = i * sweepAngle - pi / 2;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.05, false,
        Paint()
          ..color = phases[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round,
      );
    }

    // Animated dot on ring
    final dotAngle = -pi / 2 + progress * 2 * pi;
    final dotX = cx + 72 * cos(dotAngle);
    final dotY = cy + 72 * sin(dotAngle);

    // Glow
    canvas.drawCircle(Offset(dotX, dotY), 16,
        Paint()..color = const Color(0xFFE05D6F).withOpacity(0.2));
    // White dot
    canvas.drawCircle(Offset(dotX, dotY), 10,
        Paint()..color = Colors.white);
    // Color center
    canvas.drawCircle(Offset(dotX, dotY), 5,
        Paint()..color = const Color(0xFFE05D6F));

    // Center text area
    canvas.drawCircle(Offset(cx, cy), 45,
        Paint()..color = Colors.white.withOpacity(0.9));

    // Mini phase icons as dots
    for (var i = 0; i < 4; i++) {
      final angle = i * (pi / 2) - pi / 4;
      const r = 28.0;
      canvas.drawCircle(
        Offset(cx + r * cos(angle), cy + r * sin(angle)),
        8, Paint()..color = phases[i].withOpacity(0.7),
      );
    }
  }

  // ── Step 2: Date picker — Calendar ──────────────────────────
  void _paintCalendar(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const pink = Color(0xFFE05D6F);
    const teal = Color(0xFF1D9E75);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 4, cy + 8),
            width: 160, height: 160),
        const Radius.circular(20),
      ),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    // Calendar body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy),
            width: 160, height: 160),
        const Radius.circular(20),
      ),
      Paint()..color = Colors.white,
    );

    // Header
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - 80, cy - 80, 160, 45),
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
      ),
      Paint()..color = pink,
    );

    // Month text area
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 40, cy - 70, 80, 18),
        const Radius.circular(9),
      ),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    // Calendar hooks
    final hookPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 25, cy - 85),
        Offset(cx - 25, cy - 70), hookPaint);
    canvas.drawLine(Offset(cx + 25, cy - 85),
        Offset(cx + 25, cy - 70), hookPaint);

    // Day grid
    const cols = 4;
    const rows = 3;
    const cellW = 28.0;
    const cellH = 24.0;
    final gridStartX = cx - (cols * cellW) / 2 + cellW / 2;
    final gridStartY = cy - 18.0;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = gridStartX + c * cellW;
        final y = gridStartY + r * cellH;
        final isHighlighted = r == 1 && c == 2;
        final isPink = r == 0 && c == 0;
        final isTeal = r == 2 && c == 3;

        final color = isHighlighted
            ? pink
            : isPink
                ? pink.withOpacity(0.3)
                : isTeal
                    ? teal.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15);

        canvas.drawCircle(
          Offset(x, y), isHighlighted ? 11 : 8,
          Paint()..color = color,
        );
      }
    }

    // Animated check on highlighted day
    if (progress > 0.5) {
      final opacity = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(gridStartX + 2 * cellW, gridStartY + 1 * cellH),
        5,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // Floating hearts/sparkles around calendar
    _drawSparkle(canvas,
        Offset(cx + 90, cy - 60), 6, progress);
    _drawSparkle(canvas,
        Offset(cx - 85, cy + 50), 5, progress * 0.8);
    _drawSparkle(canvas,
        Offset(cx + 70, cy + 70), 4, progress * 0.6);
  }

  void _drawAnimatedStar(Canvas canvas, Offset center,
      double size, double progress, Color color) {
    final opacity = 0.4 + progress * 0.6;
    final actualSize = size * (0.7 + progress * 0.3);
    final paint = Paint()..color = color.withOpacity(opacity);

    canvas.drawCircle(center, actualSize, paint);
    // Cross lines for star effect
    final linePaint = Paint()
      ..color = color.withOpacity(opacity * 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(center.dx, center.dy - actualSize * 2),
        Offset(center.dx, center.dy + actualSize * 2), linePaint);
    canvas.drawLine(
        Offset(center.dx - actualSize * 2, center.dy),
        Offset(center.dx + actualSize * 2, center.dy), linePaint);
  }

  void _drawSparkle(Canvas canvas, Offset center,
      double size, double progress) {
    final paint = Paint()
      ..color = const Color(0xFFE05D6F).withOpacity(
          0.3 + progress * 0.4);
    canvas.drawCircle(center, size, paint);

    final linePaint = Paint()
      ..color = const Color(0xFFE05D6F).withOpacity(0.2)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      canvas.drawLine(
        Offset(center.dx + size * 1.2 * cos(angle),
            center.dy + size * 1.2 * sin(angle)),
        Offset(center.dx + size * 2 * cos(angle),
            center.dy + size * 2 * sin(angle)),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) =>
      old.progress != progress;
}
