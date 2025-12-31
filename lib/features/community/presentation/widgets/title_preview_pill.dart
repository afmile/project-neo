/// Project Neo - Title Preview Pill Widget
///
/// Reusable widget for displaying title preview with custom colors
library;

import 'package:flutter/material.dart';

class TitlePreviewPill extends StatelessWidget {
  final String text;
  final String textColor;
  final String backgroundColor;
  final double fontSize;
  final EdgeInsets padding;

  const TitlePreviewPill({
    super.key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(backgroundColor);
    final fgColor = _parseColor(textColor);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fgColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text.isEmpty ? 'Vista previa' : text,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      final fullHex = hex.length == 6 ? 'FF$hex' : hex;
      return Color(int.parse(fullHex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
