import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo « Google » dessiné à la main : aucune dépendance à un asset externe.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Google',
      child: SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _GoogleLogoPainter()),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    // Un demi-tour (180°) sert d'unité aux angles ci-dessous.
    const halfTurn = math.pi;
    final strokeWidth = size.width * 0.22;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color color, {StrokeCap cap = StrokeCap.butt}) {
      return Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = cap;
    }

    // Anneau du « G » : l'ouverture située à droite accueille la barre bleue.
    canvas.drawArc(rect, halfTurn, 0.42 * halfTurn, false, arcPaint(_red));
    canvas.drawArc(
      rect,
      1.42 * halfTurn,
      0.40 * halfTurn,
      false,
      arcPaint(_blue),
    );
    canvas.drawArc(
      rect,
      0.04 * halfTurn,
      0.46 * halfTurn,
      false,
      arcPaint(_green),
    );
    canvas.drawArc(
      rect,
      0.5 * halfTurn,
      0.5 * halfTurn,
      false,
      arcPaint(_yellow),
    );

    canvas.drawLine(
      center,
      Offset(center.dx + radius, center.dy),
      arcPaint(_blue, cap: StrokeCap.round),
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
