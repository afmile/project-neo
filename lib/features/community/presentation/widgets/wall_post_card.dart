/// Project Neo - Wall Post Card
///
/// Threads-style minimal post design for user walls with expandable comments
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/wall_post_comment.dart';
import '../../data/models/wall_post_comment_model.dart';
import '../screens/wall_post_thread_screen.dart';

class WallPostCard extends ConsumerStatefulWidget {
  final WallPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final bool canDelete;
  final bool isThreadView;

  const WallPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.canDelete = false,
    this.isThreadView = false,
  });

  @override
  ConsumerState<WallPostCard> createState() => _WallPostCardState();
}

class _WallPostCardState extends ConsumerState<WallPostCard> {
  bool _isExpanded = false;
  List<WallPostComment>? _comments;
  bool _isLoadingComments = false;

  Future<void> _toggleComments() async {
    if (widget.isThreadView) return; // Disable toggle in thread view

    if (_isExpanded) {
      // Collapse
      setState(() {
        _isExpanded = false;
      });
    } else {
      // Expand and fetch comments
      setState(() {
        _isExpanded = true;
        _isLoadingComments = true;
      });

      try {
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('wall_post_comments')
            .select('*, author:users_global!wall_post_comments_author_id_fkey(username, avatar_global_url)')
            .eq('post_id', widget.post.id)
            .order('created_at', ascending: true);

        final comments = WallPostCommentModel.listFromSupabase(response as List<dynamic>);

        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      } catch (e) {
        print('❌ ERROR LOADING COMMENTS: $e');
        setState(() {
          _isLoadingComments = false;
          _isExpanded = false;
        });
      }
    }
  }

  void _navigateToThread(bool autoFocus) {
    if (widget.isThreadView) return; // Prevent navigation if already in thread view
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WallPostThreadScreen(
          post: widget.post,
          autoFocusInput: autoFocus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If in thread view, we just return the simple column (no InkWell needed for body navigation)
    // If in feed view, we wrap in InkWell to navigate to thread
    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Avatar with conditional line
              Column(
                children: [
                  // Avatar
                  _buildAvatar(),
                  
                  // Vertical connecting line logic
                  // In Thread View: we don't show the internal line logic here, 
                  // instead the Screen will handle drawing the line to the list below if needed.
                  // In Feed View: we show line if expanded.
                  if (!widget.isThreadView && _isExpanded && _comments != null && _comments!.isNotEmpty)
                    Container(
                      width: 2,
                      height: 40,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey.withValues(alpha: 0.3),
                            Colors.grey.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
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
                      widget.post.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Action Buttons Row
                    _buildActionBar(),
                    
                    // Comments: Only show toggle in Feed View
                    if (!widget.isThreadView && widget.post.commentsCount > 0) ...[ 
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _toggleComments,
                        child: Row(
                          children: [
                            Text(
                              _isExpanded 
                                  ? 'Ocultar comentarios'
                                  : 'Ver ${widget.post.commentsCount} comentario${widget.post.commentsCount != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.grey.withValues(alpha: 0.6),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Expanded Comments Section (Only in Feed View)
        if (!widget.isThreadView && _isExpanded) ...[
          if (_isLoadingComments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 68, vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: NeoColors.accent,
                  ),
                ),
              ),
            )
          else if (_comments != null && _comments!.isNotEmpty)
            ..._comments!.map((comment) => _buildCommentItem(comment)),
        ],
        
        // Subtle divider at the bottom (Only in Feed View)
        if (!widget.isThreadView)
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.1),
            indent: 68, // Aligned with content column
          ),
      ],
    );

    if (widget.isThreadView) return content;

    return InkWell(
      onTap: () => _navigateToThread(false),
      child: content,
    );
  }

  Widget _buildCommentItem(WallPostComment comment) {
    return Padding(
      padding: const EdgeInsets.only(left: 68, right: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small avatar
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NeoColors.accent.withValues(alpha: 0.2),
              border: Border.all(
                color: NeoColors.accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      comment.authorAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        color: NeoColors.accent,
                        size: 12,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: NeoColors.accent,
                    size: 12,
                  ),
          ),
          
          const SizedBox(width: 8),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author and time
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt, locale: 'es'),
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  comment.content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: widget.post.authorAvatar != null && widget.post.authorAvatar!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                widget.post.authorAvatar!,
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
          widget.post.authorName,
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
          timeago.format(widget.post.timestamp, locale: 'es'),
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
          itemBuilder: (context) => widget.canDelete
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
            if (value == 'delete' && widget.onDelete != null) {
              widget.onDelete!();
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
          icon: widget.post.isLikedByCurrentUser
              ? Icons.favorite
              : Icons.favorite_border,
          label: widget.post.likes > 0 ? '${widget.post.likes}' : null,
          color: widget.post.isLikedByCurrentUser ? Colors.red : null,
          onTap: widget.onLike,
        ),
        
        const SizedBox(width: 20),
        
        // Comment button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: null,
          onTap: () {
            if (widget.isThreadView) {
              // If already in thread view, maybe focus input? 
              // For now, let's trigger the callback passed from parent if any 
              // or just rely on the user to tap the bottom text field.
              // But standard behavior is to focus the text field.
              widget.onComment?.call(); 
            } else {
              _navigateToThread(true);
            }
          },
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
