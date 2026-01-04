/// Project Neo - Wall Post Item
///
/// Threaded Bento Card layout for community walls
/// Two-column design: Timeline (left) + Content Card (right)
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/wall_post_comment.dart';
import 'post_options_sheet.dart';

class WallPostItem extends StatelessWidget {
  final WallPost post;
  
  /// Optional first comment to display inline
  final WallPostComment? firstComment;
  
  /// Callbacks
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onCommentLike;
  final VoidCallback? onCommentReply;
  final VoidCallback? onMenuTap;

  const WallPostItem({
    super.key,
    required this.post,
    this.firstComment,
    this.onLike,
    this.onReply,
    this.onCommentLike,
    this.onCommentReply,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasComments = post.commentsCount > 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      // ==========================================
      // ROOT: BENTO CARD (Slate 800 Background)
      // ==========================================
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Slate 800
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // COLUMN 1: TIMELINE (Left - Fixed ~56px)
              // ==========================================
              SizedBox(
                width: 56,
                child: Stack(
                  children: [
                    // Layer 1: Vertical Stitch Line (ONLY if comments exist)
                    if (hasComments)
                      Positioned(
                        top: 24 + 24, // Start below main avatar center
                        bottom: 0,
                        left: 28 - 1, // Centered horizontally
                        child: Container(
                          width: 2,
                          color: const Color(0xFF334155), // Slate 700
                        ),
                      ),
                    
                    // Layer 2: Main Avatar
                    Positioned(
                      top: 0,
                      left: 4, // Center in 56px width
                      child: CircleAvatar(
                        radius: 24,
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
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    
                    // Layer 3: Child Avatar (ONLY if comments exist)
                    if (hasComments && firstComment != null)
                      Positioned(
                        bottom: 0,
                        left: 10, // Offset to align with line
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: NeoColors.accent.withValues(alpha: 0.12),
                          backgroundImage: firstComment!.authorAvatar != null &&
                                  firstComment!.authorAvatar!.isNotEmpty
                              ? NetworkImage(firstComment!.authorAvatar!)
                              : null,
                          child: firstComment!.authorAvatar == null ||
                                  firstComment!.authorAvatar!.isEmpty
                              ? Text(
                                  firstComment!.authorName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: NeoColors.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // ==========================================
              // COLUMN 2: CONTENT (Right - Expanded)
              // ==========================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // BLOCK A: MAIN POST
                    // ==========================================
                    _buildMainPost(context),
                    
                    // ==========================================
                    // BLOCK B: INLINE COMMENT (if exists)
                    // ==========================================
                    if (hasComments && firstComment != null) ...[
                      const SizedBox(height: 16),
                      const Divider(
                        color: Color(0xFF334155),
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      _buildInlineComment(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the main post content (Block A)
  Widget _buildMainPost(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Name + Badge + Time
        Row(
          children: [
            Text(
              post.authorName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 6),
            // Verified badge (optional - you can add a field to WallPost)
            const Icon(
              Icons.verified,
              color: Color(0xFF3B82F6), // Blue
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(post.timestamp),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Body: Content text
        Text(
          post.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        
        // TODO: Media image support
        // if (post.mediaUrl != null) _buildMediaImage(post.mediaUrl!),
        
        const SizedBox(height: 16),
        
        // Footer: Actions
        Row(
          children: [
            // Like icon
            InkWell(
              onTap: onLike,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post.isLikedByCurrentUser
                          ? Colors.red[400]
                          : Colors.grey[400],
                      size: 20,
                    ),
                    if (post.likes > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        post.likes.toString(),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Reply pill
            InkWell(
              onTap: onReply,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF136DEC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Responder',
                  style: TextStyle(
                    color: Color(0xFF3B82F6), // Blue
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Menu icon
            InkWell(
              onTap: () {
                if (onMenuTap != null) {
                  onMenuTap!();
                } else {
                  showPostOptionsSheet(context, content: post.content);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build the inline comment (Block B)
  Widget _buildInlineComment(BuildContext context) {
    if (firstComment == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small name
        Text(
          firstComment!.authorName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        
        const SizedBox(height: 6),
        
        // Comment text
        Text(
          firstComment!.content,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            height: 1.4,
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Like and Reply text buttons
        Row(
          children: [
            InkWell(
              onTap: onCommentLike,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 4.0,
                ),
                child: Text(
                  firstComment!.isLikedByCurrentUser ? 'Liked' : 'Like',
                  style: TextStyle(
                    color: firstComment!.isLikedByCurrentUser
                        ? const Color(0xFF3B82F6)
                        : Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            InkWell(
              onTap: onCommentReply,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 4.0,
                ),
                child: Text(
                  'Reply',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            if (firstComment!.likesCount > 0) ...[
              const Spacer(),
              Text(
                '${firstComment!.likesCount} ${firstComment!.likesCount == 1 ? 'like' : 'likes'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        
        // Show more comments indicator
        if (post.commentsCount > 1) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: onReply, // Navigate to full comments
            child: Text(
              'Ver ${post.commentsCount - 1} ${post.commentsCount - 1 == 1 ? 'comentario más' : 'comentarios más'}',
              style: const TextStyle(
                color: Color(0xFF3B82F6), // Blue
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
