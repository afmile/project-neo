/// Project Neo - Title Settings Item Widget
///
/// Displays a single title in the settings list with drag handle and menu
library;

import 'package:flutter/material.dart';
import '../../domain/entities/member_title.dart';
import '../../../../core/theme/neo_theme.dart';

class TitleSettingsItemWidget extends StatelessWidget {
  final MemberTitle title;
  final Color themeColor;
  final VoidCallback onHide;
  final VoidCallback? onShow;

  const TitleSettingsItemWidget({
    super.key,
    required this.title,
    required this.themeColor,
    required this.onHide,
    this.onShow,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(title.title.style.backgroundColor);
    final fgColor = _parseColor(title.title.style.foregroundColor);
    final isHidden = !title.isVisible;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHidden 
              ? NeoColors.border.withOpacity(0.3)
              : NeoColors.border,
        ),
      ),
      child: Opacity(
        opacity: isHidden ? 0.5 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          // Drag handle
          leading: Icon(
            Icons.drag_handle,
            color: NeoColors.textSecondary,
          ),
          // Title preview pill
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: fgColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  title.title.name,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isHidden) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Oculto',
                    style: TextStyle(
                      color: NeoColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Menu button
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: NeoColors.textSecondary,
            ),
            color: NeoColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              if (isHidden)
                PopupMenuItem(
                  value: 'show',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: themeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mostrar título',
                        style: TextStyle(color: NeoColors.textPrimary),
                      ),
                    ],
                  ),
                )
              else
                PopupMenuItem(
                  value: 'hide',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ocultar título',
                        style: TextStyle(color: NeoColors.textPrimary),
                      ),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'hide') {
                onHide();
              } else if (value == 'show' && onShow != null) {
                onShow!();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Parse hex color from string
  Color _parseColor(String hexColor) {
    try {
      // Remove # if present
      final hex = hexColor.replaceAll('#', '');
      
      // Add FF for alpha if not present
      final fullHex = hex.length == 6 ? 'FF$hex' : hex;
      
      return Color(int.parse(fullHex, radix: 16));
    } catch (e) {
      // Fallback colors
      return hexColor.contains('bg') || hexColor.contains('background')
          ? NeoColors.card
          : NeoColors.textPrimary;
    }
  }
}
