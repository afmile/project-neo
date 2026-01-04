/// Project Neo - Post Options Bottom Sheet
///
/// Dark premium design modal sheet for post actions
library;

import 'package:flutter/material.dart';

/// Shows a bottom sheet with post options
///
/// Displays options: Share, Copy text, Block account, Report
void showPostOptionsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _PostOptionsSheet(),
  );
}

class _PostOptionsSheet extends StatelessWidget {
  const _PostOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C2229), // Dark Grey
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Header: Title + Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'More options',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Menu items (top to bottom order)
          _buildMenuItem(
            context: context,
            icon: Icons.ios_share,
            label: 'Compartir',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement share functionality
            },
          ),
          
          _buildMenuItem(
            context: context,
            icon: Icons.content_copy,
            label: 'Copiar texto',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement copy text functionality
            },
          ),
          
          _buildMenuItem(
            context: context,
            icon: Icons.block,
            label: 'Bloquear cuenta',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement block account functionality
            },
          ),
          
          // Destructive item
          _buildMenuItem(
            context: context,
            icon: Icons.report,
            label: 'Reportar',
            isDestructive: true,
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement report functionality
            },
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? Colors.red[400]! : Colors.white;
    final textColor = isDestructive ? Colors.red[400]! : Colors.white;
    final backgroundColor = isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Label
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
