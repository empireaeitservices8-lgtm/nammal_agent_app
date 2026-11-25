import 'package:flutter/material.dart';
import '../../../core/config/app_colors.dart';

class NammalLogoCard extends StatelessWidget {
  final double size;

  const NammalLogoCard({super.key, this.size = 175});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NammalIcon(size: 52),
            const SizedBox(height: 10),
            Text(
              'nammal',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.primary,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NammalIcon extends StatelessWidget {
  final double size;

  const NammalIcon({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.95,
      child: CustomPaint(
        painter: _NammalIconPainter(),
      ),
    );
  }
}

class _NammalIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.088;
    final bubblePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bubbleWidth = size.width;
    final bubbleHeight = size.height * 0.84;
    final rrectRadius = size.width * 0.26;

    // Chat Bubble Path with tail at bottom-left
    final path = Path();
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        bubbleWidth - strokeWidth,
        bubbleHeight - strokeWidth,
      ),
      Radius.circular(rrectRadius),
    );

    // Draw speech bubble frame
    path.addRRect(bubbleRect);

    // Add pointer tail on the bottom left
    final tailPath = Path();
    final startX = bubbleWidth * 0.26;
    final tailBottomX = bubbleWidth * 0.12;
    final tailBottomY = size.height;
    final endX = bubbleWidth * 0.38;

    tailPath.moveTo(startX, bubbleHeight - strokeWidth / 2);
    tailPath.lineTo(tailBottomX, tailBottomY);
    tailPath.lineTo(endX, bubbleHeight - strokeWidth / 2);

    canvas.drawPath(path, bubblePaint);
    canvas.drawPath(tailPath, bubblePaint);

    // Heart in the center
    final heartPaint = Paint()
      ..color = const Color(0xFFE53950)
      ..style = PaintingStyle.fill;

    final cx = bubbleWidth * 0.50;
    final cy = bubbleHeight * 0.48;
    final hw = size.width * 0.30;
    final hh = size.height * 0.28;

    final heartPath = Path();
    heartPath.moveTo(cx, cy + hh * 0.45);
    heartPath.cubicTo(
      cx - hw * 0.6,
      cy + hh * 0.05,
      cx - hw * 0.6,
      cy - hh * 0.45,
      cx - hw * 0.25,
      cy - hh * 0.45,
    );
    heartPath.cubicTo(
      cx - hw * 0.05,
      cy - hh * 0.45,
      cx,
      cy - hh * 0.2,
      cx,
      cy - hh * 0.1,
    );
    heartPath.cubicTo(
      cx,
      cy - hh * 0.2,
      cx + hw * 0.05,
      cy - hh * 0.45,
      cx + hw * 0.25,
      cy - hh * 0.45,
    );
    heartPath.cubicTo(
      cx + hw * 0.6,
      cy - hh * 0.45,
      cx + hw * 0.6,
      cy + hh * 0.05,
      cx,
      cy + hh * 0.45,
    );
    heartPath.close();

    canvas.drawPath(heartPath, heartPaint);

    // Three horizontal white dots inside heart
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotRadius = size.width * 0.022;
    final dotSpacing = size.width * 0.06;
    final dotY = cy - hh * 0.02;

    canvas.drawCircle(Offset(cx - dotSpacing, dotY), dotRadius, dotPaint);
    canvas.drawCircle(Offset(cx, dotY), dotRadius, dotPaint);
    canvas.drawCircle(Offset(cx + dotSpacing, dotY), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
