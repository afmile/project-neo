/// Project Neo - Bento Post Card
///
/// Modern Bento-style post card with clean aesthetic
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/wall_post_comment.dart';
import 'post_options_sheet.dart';

/// Modern Bento-style post card
class BentoPostCard extends StatefulWidget {
  final WallPost post;
  
  /// Optional first comment to display inline when expanded
  final WallPostComment? firstComment;
  
  /// Callbacks
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onCommentLike;
  final VoidCallback? onTapComments;
  final VoidCallback? onDelete;
  
  /// If true, removes bottom border radius and bottom border for connecting to lists
  final bool forceUnroundedBottom;
  
  /// If true, hides the "Ver X respuestas más" link (used in thread screen where all comments are shown)
  final bool hideMoreCommentsLink;
  
  const BentoPostCard({
    super.key,
    required this.post,
    this.firstComment,
    this.onLike,
    this.onComment,
    this.onCommentLike,
    this.onTapComments,
    this.onDelete,
    this.forceUnroundedBottom = false,
    this.hideMoreCommentsLink = false,
  });

  @override
  State<BentoPostCard> createState() => _BentoPostCardState();
}

class _BentoPostCardState extends State<BentoPostCard> {


  @override
  Widget build(BuildContext context) {
    final firstComment = widget.firstComment ?? widget.post.firstComment;
    final hasComment = firstComment != null;
    
    return Padding(
      // If unrounded bottom, eliminate bottom padding to connect perfectly
      padding: widget.forceUnroundedBottom 
          ? const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0)
          : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2633), // Dark Slate
          borderRadius: widget.forceUnroundedBottom
              ? const BorderRadius.vertical(top: Radius.circular(24.0))
              : BorderRadius.circular(24.0),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
            bottom: widget.forceUnroundedBottom 
                ? BorderSide.none 
                : BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
          ),
        ),
        // We use a Column of Rows to achieve the layout while maintaining vertical alignment flexibility
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Parent Post Section (Avatar + Header + Content)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Rail: Parent Avatar + Thread Start Line
                      SizedBox(
                        width: 40,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Thread Line (only if comment exists)
                            // Starts from center of avatar (20px) down to bottom
                            if (hasComment)
                              Positioned(
                                top: 20,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            
                            // Parent Avatar
                            _buildAvatar(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Right Rail: Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderMetadata(),
                            const SizedBox(height: 4),
                            if (widget.post.mediaUrl != null) _buildMedia(),
                            _buildContent(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Actions Section (with Thread Line passing through)
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left Rail: Thread Line
                      SizedBox(
                        width: 40,
                        child: (hasComment || widget.forceUnroundedBottom) 
                          ? Center(
                              child: Container(
                                width: 2,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            )
                          : null,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Right Rail: Actions
                      Expanded(child: _buildActions()),
                    ],
                  ),
                ),

                // 3. Comment Section (if exists)
                if (hasComment) 
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                // Left Rail: Thread Line End + Comment Avatar
                        SizedBox(
                          width: 40,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Thread Line
                              // If unrounded (connected), line goes full height
                              // If rounded (end), line stops at 16px
                              Positioned(
                                top: 0,
                                bottom: widget.forceUnroundedBottom ? 0 : null,
                                height: widget.forceUnroundedBottom ? null : 16, 
                                child: Container(
                                  width: 2,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              
                              // Comment Avatar
                              _buildCommentAvatar(firstComment!),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Right Rail: Comment Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               _buildInlineCommentContent(firstComment!),
                               if (widget.post.commentsCount > 1 && !widget.hideMoreCommentsLink)
                                  _buildMoreCommentsLink(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // If no comment but more comments link needed (rare edge case where firstComment might be null but count > 0? Shouldn't happen ideally but consistent with old logic)
                if (!hasComment && widget.post.commentsCount > 0 && !widget.hideMoreCommentsLink)
                   Padding(
                     padding: const EdgeInsets.only(left: 52), // 40 + 12
                     child: _buildMoreCommentsLink(),
                   ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to profile
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: NeoColors.accent.withValues(alpha: 0.15),
        backgroundImage: widget.post.authorAvatar != null
            ? CachedNetworkImageProvider(widget.post.authorAvatar!)
            : null,
        child: widget.post.authorAvatar == null
            ? Text(
                widget.post.authorName[0].toUpperCase(),
                style: const TextStyle(
                  color: NeoColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              )
            : null,
      ),
    );
  }
  
  Widget _buildHeaderMetadata() {
     return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
              widget.post.authorDisplayName ?? widget.post.authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTime(widget.post.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu button (3 dots)
          IconButton(
            onPressed: () => showPostOptionsSheet(context, content: widget.post.content),
            icon: Icon(
              Icons.more_horiz,
              color: Colors.grey[400],
              size: 24,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      );
  }

  Widget _buildMedia() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: CachedNetworkImage(
            imageUrl: widget.post.mediaUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[850],
              child: const Center(
                child: CircularProgressIndicator(
                  color: NeoColors.accent,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[850],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        widget.post.content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.5,
          letterSpacing: 0,
        ),
      ),
    );
  }
  
  // Replaces _buildActions - now just the content of the actions
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Like button
              InkWell(
                onTap: widget.onLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.post.isLikedByCurrentUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.post.isLikedByCurrentUser
                            ? Colors.red[400]
                            : Colors.grey[400],
                        size: 20,
                      ),
                      if (widget.post.likes > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.post.likes.toString(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Comment button 
              InkWell(
                onTap: widget.onComment,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey,
                        size: 19,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.post.commentsCount.toString(),
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentAvatar(WallPostComment comment) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: NeoColors.accent.withValues(alpha: 0.12),
      backgroundImage: comment.authorAvatar != null
          ? CachedNetworkImageProvider(comment.authorAvatar!)
          : null,
      child: comment.authorAvatar == null
          ? Text(
              comment.authorName[0].toUpperCase(),
              style: const TextStyle(
                color: NeoColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            )
          : null,
    );
  }

  Widget _buildInlineCommentContent(WallPostComment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author + Time
        Row(
          children: [
            Text(
              comment.authorDisplayName ?? comment.authorName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatTime(comment.createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        Text(
          comment.content,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Comment Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: widget.onCommentLike,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          Icon(
                            comment.isLikedByCurrentUser 
                                ? Icons.favorite 
                                : Icons.favorite_border,
                            size: 16, // Slightly smaller than parent
                            color: comment.isLikedByCurrentUser 
                                ? Colors.red[400] 
                                : Colors.grey[500],
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likesCount}',
                               style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                       ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: widget.onTapComments,
                  borderRadius: BorderRadius.circular(12),
                   child: Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                     child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 15,
                         // Slightly smaller than parent
                        color: Colors.grey,
                     ),
                   ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Link to view more comments
  Widget _buildMoreCommentsLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: widget.onTapComments,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: Text(
            'Ver ${widget.post.commentsCount - 1} ${widget.post.commentsCount - 1 == 1 ? 'respuesta más' : 'respuestas más'}',
            style: const TextStyle(
              color: NeoColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
