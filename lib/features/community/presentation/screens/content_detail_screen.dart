/// Project Neo - Content Detail Screen
///
/// Display content with editorial layout, parallax header, and social footer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../providers/content_providers.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  final PostEntity? initialPost; // For hero animation continuity

  const ContentDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  ConsumerState<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  final _scrollController = ScrollController();
  final _commentController = TextEditingController();
  bool _showHeader = true;
  double _headerOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newOpacity = (1 - (offset / 200)).clamp(0.0, 1.0);
    if (newOpacity != _headerOpacity) {
      setState(() {
        _headerOpacity = newOpacity;
        _showHeader = offset < 180;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: postAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(e.toString()),
        data: (post) {
          if (post == null) return _buildError('Post no encontrado');
          return _buildContent(post);
        },
      ),
    );
  }

  Widget _buildLoading() {
    // Use initial post if available for faster perceived loading
    if (widget.initialPost != null) {
      return _buildContent(widget.initialPost!);
    }
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(postDetailProvider(widget.postId)),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PostEntity post) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Parallax header
            _buildParallaxHeader(post),
            
            // Content body
            SliverToBoxAdapter(
              child: _buildBody(post),
            ),
            
            // Comments section
            SliverToBoxAdapter(
              child: _buildCommentsSection(post),
            ),
            
            // Bottom padding for social footer
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
        
        // Floating back button
        _buildBackButton(),
        
        // Social footer
        _buildSocialFooter(post),
      ],
    );
  }

  Widget _buildParallaxHeader(PostEntity post) {
    final hasCover = post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty;
    
    return SliverAppBar(
      expandedHeight: hasCover ? 280 : 120,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1A1A2E),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: hasCover
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    post.coverImageUrl!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0D0D1A).withOpacity(0.7),
                          const Color(0xFF0D0D1A),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.3),
                      const Color(0xFF8B5CF6).withOpacity(0.2),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      child: AnimatedOpacity(
        opacity: _showHeader ? 1.0 : 0.7,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PostEntity post) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTypeBadgeColor(post.postType),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              post.postType.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            post.title ?? 'Sin título',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 16),
          
          // Author info
          _buildAuthorInfo(post).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 24),
          
          // Content based on type
          if (post.postType == PostType.poll)
            _buildPollContent(post)
          else
            _buildTextContent(post),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(PostEntity post) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF6366F1),
          backgroundImage: post.authorAvatarUrl != null
              ? NetworkImage(post.authorAvatarUrl!)
              : null,
          child: post.authorAvatarUrl == null
              ? Text(
                  (post.authorUsername ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorUsername ?? 'Usuario',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDate(post.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent(PostEntity post) {
    return Text(
      post.content ?? '',
      style: TextStyle(
        color: Colors.white.withOpacity(0.85),
        fontSize: 16,
        height: 1.7,
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPollContent(PostEntity post) {
    final options = post.pollOptions ?? [];
    final totalVotes = post.totalVotes;
    final hasVoted = post.hasVoted;
    
    return Column(
      children: options.map((option) {
        final isSelected = option.id == post.selectedOptionId;
        final percentage = totalVotes > 0 
            ? (option.votesCount / totalVotes * 100)
            : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: hasVoted ? null : () => _votePoll(option.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF6366F1) 
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasVoted)
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (hasVoted) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(
                          isSelected 
                              ? const Color(0xFF6366F1) 
                              : Colors.white.withOpacity(0.3),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (300 + options.indexOf(option) * 50).ms);
      }).toList(),
    );
  }

  Future<void> _votePoll(String optionId) async {
    final notifier = ref.read(pollVoteProvider(widget.postId).notifier);
    await notifier.vote(optionId);
    ref.invalidate(postDetailProvider(widget.postId));
  }

  Widget _buildCommentsSection(PostEntity post) {
    final commentsState = ref.watch(commentsProvider(widget.postId));
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Comentarios (${post.commentsCount})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Comment input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submitComment,
                icon: const Icon(Icons.send, color: Color(0xFF6366F1)),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Comments list
          if (commentsState.isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (commentsState.comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sé el primero en comentar',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            )
          else
            ...commentsState.comments.map((c) => _buildCommentItem(c)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentEntity comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6366F1),
                backgroundImage: comment.authorAvatarUrl != null
                    ? NetworkImage(comment.authorAvatarUrl!)
                    : null,
                child: comment.authorAvatarUrl == null
                    ? Text(
                        (comment.authorUsername ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.authorUsername ?? 'Usuario',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(comment.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Nested replies
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 12),
              child: Column(
                children: comment.replies!.map((r) => _buildReplyItem(r)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(CommentEntity reply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF8B5CF6),
            child: Text(
              (reply.authorUsername ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.authorUsername ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  reply.content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final notifier = ref.read(commentsProvider(widget.postId).notifier);
    final success = await notifier.addComment(content);

    if (success && mounted) {
      _commentController.clear();
      // Refresh post to update comment count
      ref.invalidate(postDetailProvider(widget.postId));
    }
  }

  Widget _buildSocialFooter(PostEntity post) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0D1A).withOpacity(0),
              const Color(0xFF0D0D1A),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Like button
              _buildSocialButton(
                icon: post.isLikedByCurrentUser 
                    ? Icons.favorite 
                    : Icons.favorite_border,
                label: '${post.reactionsCount}',
                isActive: post.isLikedByCurrentUser,
                onTap: () => _toggleLike(post),
              ),
              
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withOpacity(0.1),
              ),
              
              // Comment button
              _buildSocialButton(
                icon: Icons.chat_bubble_outline,
                label: '${post.commentsCount}',
                onTap: () {
                  // Scroll to comments
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent - 100,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                },
              ),
              
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withOpacity(0.1),
              ),
              
              // Share button
              _buildSocialButton(
                icon: Icons.share_outlined,
                label: 'Compartir',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compartir próximamente')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.red : Colors.white.withOpacity(0.8),
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(PostEntity post) async {
    // Optimistic update is handled in the feed provider
    // For detail view, we'll also invalidate the detail provider
    final feedParams = (communityId: post.communityId, typeFilter: null as PostType?);
    ref.read(feedProvider(feedParams).notifier).toggleReaction(post.id);
    ref.invalidate(postDetailProvider(widget.postId));
  }

  Color _getTypeBadgeColor(PostType type) {
    switch (type) {
      case PostType.blog:
        return const Color(0xFF6366F1);
      case PostType.wiki:
        return const Color(0xFF10B981);
      case PostType.poll:
        return const Color(0xFFF59E0B);
      case PostType.quiz:
        return const Color(0xFFEF4444);
      case PostType.wallPost:
        return const Color(0xFF8B5CF6);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}sem';
  }
}
