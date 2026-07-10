import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_colors.dart';

class EmptyState extends StatefulWidget {
  final EmptyStateType type;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.type,
    this.onAction,
    this.actionLabel,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _configs[widget.type]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating illustration
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -_floatAnim.value),
                child: child,
              ),
              child: SizedBox(
                width: 160, height: 160,
                child: CustomPaint(
                  painter: _EmptyIllustrationPainter(
                    type: widget.type,
                    color: config['color'] as Color,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Title
            Text(
              config['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              config['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary(context),
                height: 1.5,
              ),
            ),

            if (widget.onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: widget.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: config['color'] as Color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  widget.actionLabel ??
                      config['action'] as String,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _configs = {
    EmptyStateType.noInsights: {
      'title': 'Chưa có dữ liệu phân tích',
      'subtitle': 'Bắt đầu ghi chép nhật ký hàng ngày\n'
          'để xem biểu đồ và phân tích chu kỳ của bạn.',
      'action': 'Ghi chép ngay',
      'color': Color(0xFFE05D6F),
    },
    EmptyStateType.noCalendarLog: {
      'title': 'Chưa có nhật ký ngày này',
      'subtitle': 'Chạm vào nút bên dưới để ghi lại\n'
          'cảm giác và triệu chứng của bạn hôm nay.',
      'action': 'Thêm nhật ký',
      'color': Color(0xFF5B8CDE),
    },
    EmptyStateType.noEntries: {
      'title': 'Chưa có dữ liệu',
      'subtitle': 'Hãy bắt đầu theo dõi chu kỳ của bạn\n'
          'bằng cách ghi chép nhật ký đầu tiên.',
      'action': 'Bắt đầu ngay',
      'color': Color(0xFF1D9E75),
    },
    EmptyStateType.noNotifications: {
      'title': 'Không có thông báo',
      'subtitle': 'Bạn đã cập nhật tất cả.\n'
          'Chúng tôi sẽ thông báo khi có điều quan trọng.',
      'action': 'Về trang chủ',
      'color': Color(0xFFF5A623),
    },
  };
}

enum EmptyStateType {
  noInsights,
  noCalendarLog,
  noEntries,
  noNotifications,
}

// ── Custom painter for illustrations ────────────────────────
class _EmptyIllustrationPainter extends CustomPainter {
  final EmptyStateType type;
  final Color color;

  _EmptyIllustrationPainter({
    required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case EmptyStateType.noInsights:
        _paintChartIllustration(canvas, size);
        break;
      case EmptyStateType.noCalendarLog:
        _paintCalendarIllustration(canvas, size);
        break;
      case EmptyStateType.noEntries:
        _paintMoonIllustration(canvas, size);
        break;
      case EmptyStateType.noNotifications:
        _paintBellIllustration(canvas, size);
        break;
    }
  }

  void _paintMoonIllustration(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy), 65,
      Paint()..color = color.withOpacity(0.1));

    // Moon body
    final moonPaint = Paint()..color = color.withOpacity(0.85);
    canvas.drawCircle(Offset(cx, cy), 40, moonPaint);

    // Moon shadow (crescent effect)
    canvas.drawCircle(
      Offset(cx + 14, cy - 10), 32,
      Paint()..color = color.withOpacity(0.1));

    // Stars
    final starPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    _drawStar(canvas, Offset(cx + 50, cy - 30), 4, starPaint);
    _drawStar(canvas, Offset(cx - 45, cy - 20), 3, starPaint);
    _drawStar(canvas, Offset(cx + 35, cy + 40), 3, starPaint);
    _drawStar(canvas, Offset(cx - 55, cy + 30), 5, starPaint);

    // Small dots
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      const r = 58.0;
      canvas.drawCircle(
        Offset(cx + r * cos(angle), cy + r * sin(angle)),
        2,
        Paint()..color = color.withOpacity(0.3));
    }
  }

  void _paintChartIllustration(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy), 65,
      Paint()..color = color.withOpacity(0.08));

    // Chart bars
    final barPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final barPaintLight = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final bars = [30.0, 50.0, 35.0, 55.0, 40.0];
    const barW = 14.0;
    final startX = cx - (bars.length * (barW + 6)) / 2;
    final baseY = cy + 30;

    for (var i = 0; i < bars.length; i++) {
      final x = startX + i * (barW + 6);
      final h = bars[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - h, barW, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, i == 3 ? barPaint : barPaintLight);
    }

    // Trend line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < bars.length; i++) {
      final x = startX + i * (barW + 6) + barW / 2;
      final y = baseY - bars[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Dots on line
    for (var i = 0; i < bars.length; i++) {
      final x = startX + i * (barW + 6) + barW / 2;
      final y = baseY - bars[i];
      canvas.drawCircle(Offset(x, y), 3,
          Paint()..color = color);
    }
  }

  void _paintCalendarIllustration(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background
    canvas.drawCircle(
      Offset(cx, cy), 65,
      Paint()..color = color.withOpacity(0.08));

    // Calendar body
    final bodyPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 5),
          width: 80, height: 72),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, bodyPaint);

    // Header bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 40, cy - 31, 80, 20),
        const Radius.circular(10),
      ),
      Paint()..color = color.withOpacity(0.6),
    );

    // Calendar hooks
    final hookPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx - 15, cy - 38), Offset(cx - 15, cy - 24), hookPaint);
    canvas.drawLine(
        Offset(cx + 15, cy - 38), Offset(cx + 15, cy - 24), hookPaint);

    // Grid dots
    final dotPaint = Paint()..color = color.withOpacity(0.4);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(cx - 24 + col * 16.0, cy + 8 + row * 16.0),
          3, dotPaint,
        );
      }
    }

    // Highlighted day
    canvas.drawCircle(
      Offset(cx + 24, cy + 8),
      8, Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(cx + 24, cy + 8),
      3, Paint()..color = Colors.white,
    );
  }

  void _paintBellIllustration(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background
    canvas.drawCircle(
      Offset(cx, cy), 65,
      Paint()..color = color.withOpacity(0.08));

    // Bell body
    final bellPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(cx, cy - 35);
    path.cubicTo(cx - 30, cy - 35, cx - 35, cy, cx - 35, cy + 15);
    path.lineTo(cx + 35, cy + 15);
    path.cubicTo(cx + 35, cy, cx + 30, cy - 35, cx, cy - 35);
    canvas.drawPath(path, bellPaint);

    // Bell base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 37, cy + 14, 74, 8),
        const Radius.circular(4),
      ),
      Paint()..color = color.withOpacity(0.8),
    );

    // Bell clapper
    canvas.drawCircle(
      Offset(cx, cy + 26),
      8, Paint()..color = color,
    );

    // Notification dots
    canvas.drawCircle(
      Offset(cx + 28, cy - 28), 10,
      Paint()..color = const Color(0xFFE05D6F),
    );
    // "!" in dot
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas,
        Offset(cx + 24, cy - 34));
  }

  void _drawStar(Canvas canvas, Offset center,
      double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
