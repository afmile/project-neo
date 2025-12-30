/// Project Neo - Wall Post Thread Screen
///
/// Dedicated screen for a single wall post thread (parent + comments)
/// Design matches minimal "Threads" aesthetic
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/wall_post_comment.dart';
import '../../data/models/wall_post_comment_model.dart';
import '../widgets/wall_post_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/telegram_input_bar.dart';
import '../../../../core/widgets/report_modal.dart';
import '../providers/community_providers.dart';
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
        debugPrint('👎 Unliked from $likesTable');
      } else {
        // Like: insert
        await supabase.from(likesTable).insert({
          'post_id': widget.post.id,
          'user_id': userId,
        });
        debugPrint('👍 Liked in $likesTable');
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
      if (commentsList.isNotEmpty) {
        final authorIds = commentsList.map((c) => c['author_id'] as String).toSet().toList();
        
        final localProfiles = await supabase
            .from('community_members')
            .select('user_id, nickname, avatar_url')
            .eq('community_id', widget.post.communityId)
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
      
      // Invalidate feed provider to update comments_count in Home
      ref.invalidate(wallPostsPaginatedProvider(widget.post.communityId));
      
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
                slivers: [
                  // Parent Post
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // No vertical line - using indentation only for cleaner look
                          
                        WallPostCard(
                          post: widget.post.copyWith(
                            isLikedByCurrentUser: _isLiked,
                            likes: _likesCount,
                          ),
                          isThreadView: true,
                          onLike: _toggleLike,
                          // Focus input when comment button is tapped in thread view
                          onComment: () => _commentFocusNode.requestFocus(),
                          onDelete: () {}, 
                          canDelete: false, 
                        ),
                      ],
                    ),
                  ),
                  
                  // Comments List
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: NeoColors.accent),
                      ),
                    )
                  else if (_comments == null || _comments!.isEmpty)
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
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final comment = _comments![index];
                          
                          // No horizontal connectors - straight vertical line only
                          return _buildThreadCommentItem(comment);
                        },
                        childCount: _comments!.length,
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

  Widget _buildThreadCommentItem(WallPostComment comment) {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;
    final isAuthor = currentUserId == comment.authorId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indentation for threaded look (replaces vertical line)
          const SizedBox(width: 24),
          
          // Avatar - Tappable to navigate to profile
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PublicUserProfileScreen(
                  userId: comment.authorId,
                  communityId: widget.post.communityId,
                ),
              ),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                   color: Colors.grey.withValues(alpha: 0.2),
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
                  : const Icon(Icons.person, size: 20, color: Colors.grey),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with menu
                Row(
                   children: [
                     Expanded(
                       child: Row(
                         children: [
                           GestureDetector(
                             onTap: () => Navigator.of(context).push(
                               MaterialPageRoute(
                                 builder: (context) => PublicUserProfileScreen(
                                   userId: comment.authorId,
                                   communityId: widget.post.communityId,
                                 ),
                               ),
                             ),
                             child: Text(
                               comment.authorName,
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               ),
                             ),
                           ),
                           const SizedBox(width: 6),
                           Text(
                             timeago.format(comment.createdAt),
                             style: TextStyle(
                               color: Colors.grey.withValues(alpha: 0.6),
                               fontSize: 13, 
                             ),
                           ),
                         ],
                       ),
                     ),
                     // 3-dot menu
                     PopupMenuButton<String>(
                       icon: Icon(
                         Icons.more_horiz,
                         color: Colors.grey.withValues(alpha: 0.6),
                         size: 18,
                       ),
                       color: Colors.grey[900],
                       onSelected: (value) async {
                         if (value == 'delete') {
                           await _deleteComment(comment.id);
                         } else if (value == 'report') {
                           showReportModal(
                             context: context,
                             targetType: 'comment',
                             targetId: comment.id,
                           );
                         }
                       },
                       itemBuilder: (context) => [
                         if (isAuthor)
                           const PopupMenuItem(
                             value: 'delete',
                             child: Row(
                               children: [
                                 Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                 SizedBox(width: 8),
                                 Text('Eliminar', style: TextStyle(color: Colors.red)),
                               ],
                             ),
                           ),
                         if (!isAuthor)
                           const PopupMenuItem(
                             value: 'report',
                             child: Row(
                               children: [
                                 Icon(Icons.flag_outlined, color: Colors.white, size: 18),
                                 SizedBox(width: 8),
                                 Text('Reportar', style: TextStyle(color: Colors.white)),
                               ],
                             ),
                           ),
                       ],
                     ),
                   ],
                ),
                
                const SizedBox(height: 4),
                
                // Image parsing logic
                _buildCommentContent(comment.content),
                
                const SizedBox(height: 8),
                
                // Comment like button
                GestureDetector(
                  onTap: () => _toggleCommentLike(comment),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLikedByCurrentUser 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        size: 18,
                        color: comment.isLikedByCurrentUser 
                            ? Colors.red 
                            : Colors.grey,
                      ),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likesCount}',
                          style: TextStyle(
                            color: comment.isLikedByCurrentUser 
                                ? Colors.red 
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        ref.invalidate(wallPostsPaginatedProvider(widget.post.communityId));
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
      debugPrint('❌ Error toggling comment like: $e');
      // Rollback on error
      setState(() {
        final index = _comments!.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments![index] = comment.copyWith(
            isLikedByCurrentUser: wasLiked,
            likesCount: wasLiked ? comment.likesCount : comment.likesCount - 1,
          );
        }
      });
    }
  }

  Widget _buildCommentContent(String content) {
    // Regex to detect markdown image ![Imagen](url)
    final imageRegex = RegExp(r'!\[Imagen\]\((.*?)\)');
    final match = imageRegex.firstMatch(content);

    if (match != null) {
      final imageUrl = match.group(1);
      final textContent = content.replaceAll(imageRegex, '').trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 250, // Limit height
                    minWidth: double.infinity,
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(
                             strokeWidth: 2,
                             color: NeoColors.accent
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          
          if (textContent.isNotEmpty)
            Text(
              textContent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
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
