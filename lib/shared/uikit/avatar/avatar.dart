import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AvatarStatus { online, offline, busy, away }

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.src,
    this.alt,
    this.name,
    this.icon,
    this.size = 40,
    this.status,
    this.statusColor,
    this.shape = BoxShape.circle,
  });

  final String? src;
  final String? alt;
  final String? name;
  final Widget? icon;
  final double size;
  final AvatarStatus? status;
  final Color? statusColor;
  final BoxShape shape;

  Color _getFallbackBackground(String? name) {
    if (name == null || name.isEmpty) return Colors.grey;
    final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    // Extended palette could be used here
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(name.length, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackBg = _getFallbackBackground(name);

    // Status Dot logic
    Widget? statusIndicator;
    if (status != null || statusColor != null) {
      Color dotColor = statusColor ?? Colors.green;
      if (status != null && statusColor == null) {
        switch (status!) {
          case AvatarStatus.online:
            dotColor = Colors.green;
            break;
          case AvatarStatus.offline:
            dotColor = Colors.grey;
            break;
          case AvatarStatus.busy:
            dotColor = Colors.red;
            break;
          case AvatarStatus.away:
            dotColor = Colors.orange;
            break;
        }
      }

      final dotSize = size * 0.25;

      statusIndicator = Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      );
    }

    Widget content;
    if (src != null) {
      content = Image.network(
        src!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback(fallbackBg);
        },
      );
    } else {
      content = _buildFallback(fallbackBg);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: shape,
              color: fallbackBg, // Background for image or fallback
            ),
            clipBehavior: Clip.hardEdge, // Clip image to shape
            child: content,
          ),
          if (statusIndicator != null) statusIndicator,
        ],
      ),
    );
  }

  Widget _buildFallback(Color bgColor) {
    if (icon != null) {
      return Container(
        color: bgColor,
        alignment: Alignment.center,
        child: IconTheme(
          data: IconThemeData(size: size * 0.5, color: Colors.white),
          child: icon!,
        ),
      );
    }

    if (name != null) {
      return Container(
        color: bgColor,
        alignment: Alignment.center,
        child: Text(
          _getInitials(name!),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
    );
  }
}
