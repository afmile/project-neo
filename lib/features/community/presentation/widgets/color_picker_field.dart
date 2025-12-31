/// Project Neo - Color Picker Field Widget
///
/// Reusable color picker field with visual preview
library;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/theme/neo_theme.dart';

class ColorPickerField extends StatelessWidget {
  final String label;
  final String currentColor;
  final ValueChanged<String> onColorChanged;
  final IconData icon;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.currentColor,
    required this.onColorChanged,
    this.icon = Icons.palette,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(currentColor);

    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeoColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: NeoColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: NeoColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$currentColor',
                    style: const TextStyle(
                      color: NeoColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    Color pickerColor = _parseColor(currentColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeoColors.surface,
        title: Text(
          'Seleccionar $label',
          style: const TextStyle(color: NeoColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            labelTypes: const [],
            pickerAreaBorderRadius: BorderRadius.circular(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: NeoColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final hex = pickerColor.value.toRadixString(16).substring(2);
              onColorChanged(hex.toUpperCase());
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
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
