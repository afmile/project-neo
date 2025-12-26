/// Project Neo - Wall Post Card
///
/// Threads-style minimal post design for user walls
library;

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';

class WallPostCard extends StatelessWidget {
  final WallPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final bool canDelete;

  const WallPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Avatar only (no line for independent posts)
              _buildAvatar(),
              
              const SizedBox(width: 12),
              
              // Right Column: Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Username, Time, Menu
                    _buildHeader(context),
                    
                    const SizedBox(height: 4),
                    
                    // Post Content
                    Text(
                      post.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Action Buttons Row
                    _buildActionBar(),
                    
                    // Comments count (if any)
                    if (post.commentsCount > 0) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onComment,
                        child: Text(
                          'Ver ${post.commentsCount} comentario${post.commentsCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Subtle divider at the bottom
        Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.white.withValues(alpha: 0.1),
          indent: 68, // Aligned with content column
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            NeoColors.accent.withValues(alpha: 0.3),
            NeoColors.accent.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: NeoColors.accent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                post.authorAvatar!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: NeoColors.accent,
                  size: 20,
                ),
              ),
            )
          : const Icon(
              Icons.person,
              color: NeoColors.accent,
              size: 20,
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Username
        Text(
          post.authorName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(width: 6),
        
        // Separator dot
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        
        const SizedBox(width: 6),
        
        // Relative time
        Text(
          timeago.format(post.timestamp, locale: 'es'),
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        
        const Spacer(),
        
        // 3-dot menu with delete option
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_horiz,
            color: Colors.grey.withValues(alpha: 0.6),
            size: 20,
          ),
          color: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          itemBuilder: (context) => canDelete
              ? [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red.withValues(alpha: 0.9),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.9),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : [],
          onSelected: (value) {
            if (value == 'delete' && onDelete != null) {
              onDelete!();
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        // Like button
        _buildActionButton(
          icon: post.isLikedByCurrentUser
              ? Icons.favorite
              : Icons.favorite_border,
          label: post.likes > 0 ? '${post.likes}' : null,
          color: post.isLikedByCurrentUser ? Colors.red : null,
          onTap: onLike,
        ),
        
        const SizedBox(width: 20),
        
        // Comment button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: null,
          onTap: onComment,
        ),
        

      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    Color? color,
    VoidCallback? onTap,
  }) {
    final effectiveColor = color ?? Colors.grey.withValues(alpha: 0.7);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: effectiveColor,
              size: 20,
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
