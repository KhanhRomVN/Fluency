import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Theme.of(context).extension<AppColorsExtension>()?.primary ??
            Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            Text(
              'Last 7 days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ChartPainter(
              color: primaryColor,
              gridColor: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Divider(height: 1),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.color,
    required this.gridColor,
    this.labelStyle,
  });

  final Color color;
  final Color gridColor;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 10.0;
    const verticalPadding = 20.0;
    final chartWidth = size.width - horizontalPadding;
    final chartHeight = size.height - verticalPadding;

    final points = [0.2, 0.5, 0.3, 0.7, 0.6, 0.9, 0.8];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // final yLabels = ['10h', '5h', '0h']; // Unused but listed in original

    final widthStep = chartWidth / (points.length - 1);

    // 1. Grid lines removed as requested

    // 2. Prepare Path and Gradient
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = horizontalPadding + (i * widthStep);
      final y = chartHeight * (1 - points[i]);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath
          ..moveTo(x, chartHeight)
          ..lineTo(x, y);
      } else {
        final prevX = horizontalPadding + ((i - 1) * widthStep);
        final prevY = chartHeight * (1 - points[i - 1]);

        final controlX1 = prevX + (x - prevX) / 2;
        final controlY1 = prevY;
        final controlX2 = x - (x - prevX) / 2;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }

      if (i == points.length - 1) {
        fillPath
          ..lineTo(x, chartHeight)
          ..close();
      }
    }

    // 3. Draw Gradient Fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.3),
        color.withValues(alpha: 0),
      ],
    );
    final fillPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 5. Draw Dots & X Labels
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final x = horizontalPadding + (i * widthStep);
      final y = chartHeight * (1 - points[i]);

      // X Label
      TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(
          canvas,
          Offset(x - 5, chartHeight + 8),
        );

      // Dot
      canvas
        ..drawCircle(Offset(x, y), 4, dotPaint)
        ..drawCircle(Offset(x, y), 4, dotBorderPaint);

      // Value Label above dot
      final valueText = '${(points[i] * 10).toStringAsFixed(1)}h';
      TextPainter(
        text: TextSpan(
          text: valueText,
          style: labelStyle?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(
          canvas,
          Offset(x - 10, y - 20),
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
