/// Project Neo - Facepile Widget
///
/// Displays overlapping avatars of online users.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class FacepileWidget extends StatelessWidget {
  final List<String> avatarUrls;
  final int maxVisible;
  final double size;

  const FacepileWidget({
    super.key,
    required this.avatarUrls,
    this.maxVisible = 3,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = avatarUrls.take(maxVisible).toList();
    final remaining = avatarUrls.length - maxVisible;

    return SizedBox(
      width: size * maxVisible - (maxVisible - 1) * (size * 0.3),
      height: size,
      child: Stack(
        children: [
          ...List.generate(visibleAvatars.length, (index) {
            return Positioned(
              left: index * (size * 0.7),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: visibleAvatars[index].isNotEmpty
                      ? Image.network(
                          visibleAvatars[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderAvatar(index),
                        )
                      : _buildPlaceholderAvatar(index),
                ),
              ),
            );
          }),
          // Show "+N" if there are more avatars
          if (remaining > 0)
            Positioned(
              left: visibleAvatars.length * (size * 0.7),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeoColors.accent,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar(int index) {
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];

    return Container(
      color: colors[index % colors.length],
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
