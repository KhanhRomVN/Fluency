import 'dart:ui' as ui;
import 'package:fluency/core/services/usage/daily_usage_repository.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Theme.of(context).extension<AppColorsExtension>()?.primary ??
            Theme.of(context).primaryColor;

    final usageMinutes = sl<DailyUsageRepository>().getLast7DaysMinutes();
    final labels = _generateLabels();

    // Calculate normalized points (0.0 to 1.0)
    // We assume 60 minutes is the "standard" target (1.0),
    // but if any day exceeds it, we scale relative to the max value.
    int maxMinutes =
        usageMinutes.reduce((curr, next) => curr > next ? curr : next);
    if (maxMinutes < 60) maxMinutes = 60; // Min scale of 1 hour

    final points = usageMinutes.map((m) => m / maxMinutes).toList();

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
              points: points,
              labels: labels,
              usageMinutes: usageMinutes,
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

  List<String> _generateLabels() {
    final results = <String>[];
    // Use local time (DateTime.now() is local by default in Dart)
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      results.add(DateFormat('E').format(date)); // Mon, Tue, etc.
    }
    return results;
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.labels,
    required this.usageMinutes,
    required this.color,
    required this.gridColor,
    this.labelStyle,
  });

  final List<double> points;
  final List<String> labels;
  final List<int> usageMinutes;
  final Color color;
  final Color gridColor;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 15.0;
    const verticalPadding = 20.0;
    final chartWidth = size.width - (horizontalPadding * 2);
    final chartHeight = size.height - (verticalPadding * 2);

    final widthStep = chartWidth / (points.length - 1);

    // 2. Prepare Path and Gradient
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = horizontalPadding + (i * widthStep);
      final y = verticalPadding + (chartHeight * (1 - points[i]));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath
          ..moveTo(x, verticalPadding + chartHeight)
          ..lineTo(x, y);
      } else {
        final prevX = horizontalPadding + ((i - 1) * widthStep);
        final prevY = verticalPadding + (chartHeight * (1 - points[i - 1]));

        final controlX1 = prevX + (x - prevX) / 2;
        final controlY1 = prevY;
        final controlX2 = x - (x - prevX) / 2;
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }

      if (i == points.length - 1) {
        fillPath
          ..lineTo(x, verticalPadding + chartHeight)
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
      ..shader = gradient.createShader(
          Rect.fromLTWH(0, verticalPadding, size.width, chartHeight))
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
      final y = verticalPadding + (chartHeight * (1 - points[i]));

      // X Label
      TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )
        ..layout()
        ..paint(
          canvas,
          Offset(x - 10, verticalPadding + chartHeight + 8),
        );

      // Dot
      canvas
        ..drawCircle(Offset(x, y), 4, dotPaint)
        ..drawCircle(Offset(x, y), 4, dotBorderPaint);

      // Value Label above dot (only if > 0 or for specific days to keep it clean)
      if (usageMinutes[i] > 0) {
        final valueText = '${usageMinutes[i]}m';
        TextPainter(
          text: TextSpan(
            text: valueText,
            style: labelStyle?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 9,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )
          ..layout()
          ..paint(
            canvas,
            Offset(x - 8, y - 18),
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
