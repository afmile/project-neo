/// Project Neo - Destructive Action Dialog
///
/// Reusable confirmation dialog for destructive actions (delete, remove, etc.)
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class DestructiveActionDialog {
  /// Show a confirmation dialog for destructive actions
  /// 
  /// Returns true if user confirmed, false if canceled
  static Future<bool> show({
    required BuildContext context,
    String title = '¿Eliminar?',
    required String message,
    String confirmText = 'Eliminar',
    String cancelText = 'Cancelar',
    Color confirmColor = NeoColors.error,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeoColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.cardRadius),
          side: const BorderSide(
            color: NeoColors.border,
            width: 1,
          ),
        ),
        title: Text(
          title,
          style: NeoTextStyles.headlineSmall.copyWith(
            color: NeoColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: NeoTextStyles.bodyMedium.copyWith(
            color: NeoColors.textSecondary,
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: NeoColors.textSecondary,
              ),
            ),
          ),
          
          // Confirm button (destructive)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Quick method for delete confirmation
  static Future<bool> confirmDelete({
    required BuildContext context,
    String itemName = 'esto',
  }) {
    return show(
      context: context,
      title: '¿Eliminar?',
      message: '¿Estás seguro que deseas eliminar $itemName? Esta acción no se puede deshacer.',
    );
  }

  /// Quick method for remove confirmation
  static Future<bool> confirmRemove({
    required BuildContext context,
    String itemName = 'esto',
  }) {
    return show(
      context: context,
      title: '¿Remover?',
      message: '¿Estás seguro que deseas remover $itemName?',
      confirmText: 'Remover',
    );
  }
}
