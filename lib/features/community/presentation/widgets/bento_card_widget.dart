/// Project Neo - Bento Card Widget
///
/// Reusable card component for Settings Hub with dark theme
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class BentoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback onTap;
  final String? badge;
  final bool isExpanded;

  const BentoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor,
    required this.onTap,
    this.badge,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? NeoColors.accent;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1F2937).withOpacity(0.8), // Dark gray
                const Color(0xFF111827).withOpacity(0.9), // Darker
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: effectiveColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        effectiveColor.withOpacity(0.3),
                        effectiveColor.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor.withOpacity(0.9),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    effectiveColor.withOpacity(0.3),
                                    effectiveColor.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: effectiveColor.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  color: effectiveColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Chevron with accent color
                Icon(
                  Icons.chevron_right,
                  color: effectiveColor.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header for Settings Hub (dark theme)
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  
  const SettingsSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
