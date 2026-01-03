/// Project Neo - Wall Post Item
///
/// Threads-style wall post with avatar and thread line
/// Implements the grid layout pattern from Threads
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';

class WallPostItem extends StatelessWidget {
  final WallPost post;
  final bool showThreadLine;

  const WallPostItem({
    super.key,
    required this.post,
    this.showThreadLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: Avatar + Thread Line (48dp fixed width)
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Avatar (36dp)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: NeoColors.accent.withValues(alpha: 0.15),
                    backgroundImage: post.authorAvatar != null &&
                            post.authorAvatar!.isNotEmpty
                        ? NetworkImage(post.authorAvatar!)
                        : null,
                    child: post.authorAvatar == null ||
                            post.authorAvatar!.isEmpty
                        ? Text(
                            post.authorName[0].toUpperCase(),
                            style: const TextStyle(
                              color: NeoColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                ),
                
                // Thread line (si aplica)
                if (showThreadLine)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Columna derecha: Header + Body + Footer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 4),
                
                // Body (content)
                Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Footer (acciones)
                _buildFooter(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          post.authorName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatTime(post.timestamp),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        _buildActionIcon(Icons.favorite_border, post.likes),
        const SizedBox(width: 16),
        _buildActionIcon(Icons.mode_comment_outlined, post.commentsCount),
        const SizedBox(width: 16),
        _buildActionIcon(Icons.send_outlined, null),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, int? count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return 'ahora';
    } else if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'hace ${diff.inHours}h';
    } else {
      return 'hace ${diff.inDays}d';
    }
  }
}
