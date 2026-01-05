/// Project Neo - Wall Post Thread Screen
///
/// Dedicated screen for a single wall post thread (parent + comments)
/// Design matches minimal "Threads" aesthetic
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/wall_post_comment.dart';
import '../../data/models/wall_post_comment_model.dart';
import '../widgets/bento_post_card.dart';
import '../widgets/post_options_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/telegram_input_bar.dart';
import '../providers/wall_posts_paginated_provider.dart';
import 'public_user_profile_screen.dart';

class WallPostThreadScreen extends ConsumerStatefulWidget {
  final WallPost post;
  final bool autoFocusInput;
  /// If true, uses profile_wall_post_* tables instead of wall_post_*
  final bool isProfilePost;

  const WallPostThreadScreen({
    super.key,
    required this.post,
    this.autoFocusInput = false,
    this.isProfilePost = false,
  });

  @override
  ConsumerState<WallPostThreadScreen> createState() => _WallPostThreadScreenState();
}


class _WallPostThreadScreenState extends ConsumerState<WallPostThreadScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  
  List<WallPostComment>? _comments;
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedImage;
  
  // Local state for like (since widget.post is immutable)
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser;
    _likesCount = widget.post.likes;
    _fetchComments();
    
    if (widget.autoFocusInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentFocusNode.requestFocus();
      });
    }
  }
  
  /// Toggle like on the parent post
  /// Uses profile_wall_post_likes or wall_post_likes based on isProfilePost
  Future<void> _toggleLike() async {
    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      // Choose table based on post source
      final likesTable = widget.isProfilePost 
          ? 'profile_wall_post_likes' 
          : 'wall_post_likes';
      
      if (!_isLiked) {
        // Unlike: delete the like
        await supabase
            .from(likesTable)
            .delete()
            .eq('post_id', widget.post.id)
            .eq('user_id', userId);
        debugPrint('ðŸ‘Ž Unliked from $likesTable');
      } else {
        // Like: insert
        await supabase.from(likesTable).insert({
          'post_id': widget.post.id,
          'user_id': userId,
        });
        debugPrint('ðŸ‘ Liked in $likesTable');
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      
      // Choose tables and FKs based on post source
      final commentsTable = widget.isProfilePost 
          ? 'profile_wall_post_comments' 
          : 'wall_post_comments';
      final authorFk = widget.isProfilePost
          ? 'profile_wall_post_comments_author_id_fkey'
          : 'wall_post_comments_author_id_fkey';
      final likesTable = widget.isProfilePost
          ? 'profile_wall_post_comment_likes'
          : 'wall_post_comment_likes';
      
      // Fetch comments with author and likes
      final response = await supabase
          .from(commentsTable)
          .select('*, author:users_global!$authorFk(username, avatar_global_url), user_likes:$likesTable(user_id)')
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);
      
      final commentsList = response as List<dynamic>;
      
      // Fetch local profiles for all comment authors
      if (commentsList.isNotEmpty && widget.post.communityId != null) {
        final authorIds = commentsList.map((c) => c['author_id'] as String).toSet().toList();
        
        final localProfiles = await supabase
            .from('community_members')
            .select('user_id, nickname, avatar_url')
            .eq('community_id', widget.post.communityId!)
            .inFilter('user_id', authorIds);
        
        // Create lookup map
        final profileMap = <String, Map<String, dynamic>>{};
        for (final profile in localProfiles as List) {
          profileMap[profile['user_id']] = profile;
        }
        
        // Inject local_profile into each comment
        for (final comment in commentsList) {
          final authorId = comment['author_id'] as String;
          comment['local_profile'] = profileMap[authorId];
        }
      }

      final comments = WallPostCommentModel.listFromSupabase(commentsList, currentUserId);

      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching thread comments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _handleSendComment() async {
    final content = _commentController.text.trim();
    if ((content.isEmpty && _selectedImage == null) || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final currentUser = authState.user;

      if (currentUser == null) throw Exception('User not authenticated');

      String? imageUrl;
      if (_selectedImage != null) {
        // Create unique filename
        final fileExt = _selectedImage!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${currentUser.id}.$fileExt';
        
        // Upload to 'wall_media' bucket
        await supabase.storage.from('wall_media').upload(
          fileName,
          _selectedImage!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        
        // Get public URL
        imageUrl = supabase.storage.from('wall_media').getPublicUrl(fileName);
      }

      // Insert comment - use correct table based on post source
      final commentsTable = widget.isProfilePost 
          ? 'profile_wall_post_comments' 
          : 'wall_post_comments';
      
      // Note: If the table doesn't have image_url yet, this might need an update. 
      // For now, appending image URL to content as Markdown if image exists is a safe fallback 
      // ensuring it's visible even without schema change.
      String finalContent = content;
      if (imageUrl != null) {
        if (finalContent.isNotEmpty) finalContent += '\n\n';
        finalContent += '![Imagen]($imageUrl)';
      }

      // Build insert payload - profile_wall_post_comments requires community_id
      final commentPayload = <String, dynamic>{
        'post_id': widget.post.id,
        'author_id': currentUser.id,
        'content': finalContent,
      };
      
      // Add community_id for profile comments (required by NOT NULL constraint)
      if (widget.isProfilePost) {
        commentPayload['community_id'] = widget.post.communityId;
      }

      await supabase.from(commentsTable).insert(commentPayload);

      // Reset UI
      _commentController.clear();
      setState(() {
        _selectedImage = null;
      });
      
      // Refresh comments in thread
      await _fetchComments();
      
      // Animate scroll to bottom to show new comment "entering" the card
      if (mounted) {
        // Small delay to ensure list is rebuilt
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (_scrollController.hasClients) {
          await _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      }

      // Invalidate feed provider to update comments_count in Home
      if (widget.post.communityId != null) {
        ref.invalidate(wallPostsPaginatedProvider(widget.post.communityId!));
      }
      
    } catch (e) {
      debugPrint('Error sending comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar comentario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Hilo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Parent Post
                  SliverToBoxAdapter(
                    child: BentoPostCard(
                      post: widget.post.copyWith(
                        isLikedByCurrentUser: _isLiked,
                        likes: _likesCount,
                      ),
                      onLike: _toggleLike,
                      onComment: () => _commentFocusNode.requestFocus(),
                      hideMoreCommentsLink: true, // Already in thread, all comments visible below
                      // If there are visible comments (list not empty), unround bottom
                      forceUnroundedBottom: _comments != null && _comments!.where((c) {
                             if (widget.post.firstComment == null) return true;
                             return c.id != widget.post.firstComment!.id;
                        }).isNotEmpty,
                    ),
                  ),
                  
                  // Comments List (Unified Card Style)
                  if (_isLoading)
                     const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: NeoColors.accent),
                      ),
                    )
                  else if (_comments == null || _comments!.isEmpty)
                     // If no comments, show empty state (optional, or just nothing)
                      const SliverToBoxAdapter(
                       child: Padding(
                         padding: EdgeInsets.all(32.0),
                         child: Center(
                           child: Text(
                             'Sé el primero en responder.',
                             style: TextStyle(color: Colors.grey),
                           ),
                         ),
                       ),
                     )
                  else
                    SliverPadding(
                       // Match BentoPostCard horizontal padding (16)
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Filter out duplicate first comment
                            final visibleComments = _comments!.where((c) {
                               if (widget.post.firstComment == null) return true;
                               return c.id != widget.post.firstComment!.id;
                            }).toList();
                            
                            if (index >= visibleComments.length) return null;

                            final comment = visibleComments[index];
                            final isLast = index == visibleComments.length - 1;
                            
                            // Visual container for the comment item
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20), // Match BentoPostCard inner padding
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2633), // Match Bento Card
                                // Only round bottom if last
                                borderRadius: isLast 
                                    ? const BorderRadius.vertical(bottom: Radius.circular(24.0))
                                    : null,
                                // Borders (sides + bottom if last)
                                border: Border(
                                  left: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
                                  right: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
                                  bottom: isLast 
                                      ? BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5)
                                      : BorderSide.none,
                                ),
                              ),
                              child: _buildThreadCommentItem(comment, isLast: isLast),
                            );
                          },
                          childCount: _comments!.where((c) {
                               if (widget.post.firstComment == null) return true;
                               return c.id != widget.post.firstComment!.id;
                          }).length,
                        ),
                      ),
                    ),
                    
                   // Extra space for bottom input
                   const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
            
            // Telegram-Style Input Bar
            TelegramInputBar(
              controller: _commentController,
              focusNode: _commentFocusNode,
              hintText: 'Agregar a hilo...',
              selectedImage: _selectedImage,
              isSending: _isSending,
              onSend: (_) => _handleSendComment(),
              onAttach: _pickImage,
              onRemoveImage: () => setState(() => _selectedImage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadCommentItem(WallPostComment comment, {required bool isLast}) {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;
    final isAuthor = currentUserId == comment.authorId;

    return Container(
      // Keep vertical loose but remove horizontal padding as parent container handles edges
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thread Line & Avatar Column
            SizedBox(
              width: 40, // 40 + 12 (sized box) = 52 total left rail, matches BentoPostCard
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Vertical Thread Line
                  // Extends from top. If last, stops at avatar center (20px). Else goes full height.
                  // But since parent line needs to connect, we start from top.
                  Positioned(
                    top: 0,
                    bottom: isLast ? null : 0,
                    height: isLast ? 24 : null, // Stop at approx center of avatar area
                    child: Container(
                      width: 2,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  
                  // Avatar with spacing from top to align with text
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0), // Slight top offset
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PublicUserProfileScreen(
                            userId: comment.authorId,
                            // Fallback to empty string if global post (PublicUserProfile handles fallback to global)
                            communityId: widget.post.communityId ?? '',
                          ),
                        ),
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A2633), // Match background to hide line behind
                          border: Border.all(
                             color: Colors.white.withValues(alpha: 0.1),
                             width: 1,
                          ),
                        ),
                         child: comment.authorAvatar != null
                            ? ClipOval(
                                child: Image.network(
                                  comment.authorAvatar!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  comment.authorName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: NeoColors.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Name + Time + Menu
                    Row(
                       children: [
                         Text(
                           comment.authorName,
                           style: const TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.w600,
                             fontSize: 15,
                           ),
                         ),
                         const SizedBox(width: 8),
                         Text(
                           _formatTime(comment.createdAt),
                           style: TextStyle(
                             color: Colors.grey[500],
                             fontSize: 13,
                           ),
                         ),
                         const Spacer(),
                         // 3-dot menu (always show)
                         IconButton(
                           onPressed: () {
                             showPostOptionsSheet(
                               context,
                               content: comment.content,
                               showDelete: isAuthor || (widget.post.authorId == currentUserId),
                               onDelete: () => _deleteComment(comment.id),
                             );
                           },
                           icon: Icon(Icons.more_horiz, color: Colors.grey[500], size: 20),
                           padding: EdgeInsets.zero,
                           constraints: const BoxConstraints(),
                         ),
                       ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Comment Text (Markdown/Images)
                    _buildCommentContent(comment.content),
                    
                    const SizedBox(height: 12),
                    
                    // Actions: Like, Reply
                    Row(
                      children: [
                        // Likes
                        InkWell(
                          onTap: () => _toggleCommentLike(comment),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                comment.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                                color: comment.isLikedByCurrentUser ? Colors.red : Colors.grey[500],
                                size: 16,
                              ),
                              if (comment.likesCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likesCount}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // Reply (just focus input)
                        InkWell(
                          onTap: () {
                             _commentController.text = '@${comment.authorName} ';
                             _commentFocusNode.requestFocus();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.reply, color: Colors.grey[500], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Responder',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${time.day}/${time.month}';
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Choose table based on post source
      final commentsTable = widget.isProfilePost 
          ? 'profile_wall_post_comments' 
          : 'wall_post_comments';
      
      await supabase.from(commentsTable).delete().eq('id', commentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentario eliminado'),
            backgroundColor: Colors.grey,
          ),
        );
        await _fetchComments();
        
        // Invalidate Home feed provider to update comments_count
        if (widget.post.communityId != null) {
          ref.invalidate(wallPostsPaginatedProvider(widget.post.communityId!));
        }
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Toggle like on a comment (optimistic UI)
  Future<void> _toggleCommentLike(WallPostComment comment) async {
    if (_comments == null) return;
    
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    final wasLiked = comment.isLikedByCurrentUser;
    
    // Optimistic update
    setState(() {
      final index = _comments!.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        _comments![index] = comment.copyWith(
          isLikedByCurrentUser: !wasLiked,
          likesCount: wasLiked ? comment.likesCount - 1 : comment.likesCount + 1,
        );
      }
    });
    
    try {
      // Choose table based on post source
      final likesTable = widget.isProfilePost 
          ? 'profile_wall_post_comment_likes' 
          : 'wall_post_comment_likes';
      
      if (wasLiked) {
        // Unlike: delete
        await supabase
            .from(likesTable)
            .delete()
            .eq('comment_id', comment.id)
            .eq('user_id', userId);
        debugPrint('👎 Unliked comment from $likesTable');
      } else {
        // Like: insert
        await supabase.from(likesTable).insert({
          'comment_id': comment.id,
          'user_id': userId,
          'community_id': widget.post.communityId,
        });
        debugPrint('👍 Liked comment in $likesTable');
      }
    } catch (e) {
      // Revert optimistic update
      if (mounted) {
        setState(() {
          final index = _comments!.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            _comments![index] = comment.copyWith(
              isLikedByCurrentUser: wasLiked,
              likesCount: comment.likesCount,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCommentContent(String content) {
    // Basic Markdown support (for images mainly)
    final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final hasImage = imageRegex.hasMatch(content);
    
    if (hasImage) {
      final match = imageRegex.firstMatch(content)!;
      final imageUrl = match.group(1);
      final textContent = content.replaceAll(imageRegex, '').trim();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (textContent.isNotEmpty) ...[
            Text(
              textContent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.error, color: Colors.red)),
                ),
              ),
            ),
        ],
      );
    }

    return Text(
      content,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }
}
