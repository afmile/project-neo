/// Project Neo - Hide Title Confirmation Dialog
///
/// Confirmation dialog shown when user wants to hide a title
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

/// Shows confirmation dialog for hiding a title
/// 
/// Returns `true` if user confirms, `false` if cancelled
Future<bool> showHideTitleConfirmationDialog({
  required BuildContext context,
  required String titleName,
  required Color themeColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => HideTitleConfirmationDialog(
      titleName: titleName,
      themeColor: themeColor,
    ),
  );
  
  return result ?? false;
}

class HideTitleConfirmationDialog extends StatelessWidget {
  final String titleName;
  final Color themeColor;

  const HideTitleConfirmationDialog({
    super.key,
    required this.titleName,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NeoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            color: themeColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '¿Deseas ocultar este título de tu perfil?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: themeColor.withOpacity(0.4)),
            ),
            child: Text(
              titleName,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Este título forma parte de tu historial en esta comunidad.',
            style: TextStyle(
              color: NeoColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.check_circle_outline,
            text: 'No se eliminará de la comunidad',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.money_off_outlined,
            text: 'No se reembolsará si fue comprado',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.restore_outlined,
            text: 'Podrás volver a mostrarlo cuando quieras',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeoColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: themeColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Si deseas eliminar este título definitivamente, contacta a un líder de la comunidad para solicitar su remoción.',
                    style: TextStyle(
                      color: NeoColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: NeoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Ocultar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: NeoColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
