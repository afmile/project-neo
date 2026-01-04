/// Project Neo - Reply Composer Widget
///
/// Dark mode composer for replying to wall posts
/// Two-section design: Context (top) + Composer (bottom)
library;

import 'package:flutter/material.dart';
import '../../domain/entities/wall_post.dart';
import 'wall_post_item.dart';

/// Shows a reply composer for a wall post
///
/// Can be displayed via showModalBottomSheet or Navigator.push
class ReplyComposerWidget extends StatefulWidget {
  final WallPost post;
  final VoidCallback? onImageTap;
  final VoidCallback? onGifTap;
  final VoidCallback? onStickerTap;
  final Function(String content)? onReply;

  const ReplyComposerWidget({
    super.key,
    required this.post,
    this.onImageTap,
    this.onGifTap,
    this.onStickerTap,
    this.onReply,
  });

  @override
  State<ReplyComposerWidget> createState() => _ReplyComposerWidgetState();
}

class _ReplyComposerWidgetState extends State<ReplyComposerWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleReply() {
    final content = _controller.text.trim();
    if (content.isNotEmpty && widget.onReply != null) {
      widget.onReply!(content);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101822), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF101822),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reply',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ==========================================
          // SECTION 1: CONTEXT AREA (Top - Scrollable)
          // ==========================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  // Original post (read-only)
                  WallPostItem(
                    post: widget.post,
                    // No callbacks - read-only
                  ),
                  
                  // Visual stitch line connecting to composer
                  Padding(
                    padding: const EdgeInsets.only(left: 52.0),
                    child: Container(
                      width: 2,
                      height: 40,
                      color: const Color(0xFF334155), // Grey stitch line
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ==========================================
          // SECTION 2: COMPOSER AREA (Bottom - Fixed)
          // ==========================================
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A2633), // Dark card
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Multi-line text input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 3,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Post your reply',
                      hintStyle: TextStyle(
                        color: Color(0xFF64748B), // Slate 500
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                
                // Toolbar: Icons (left) + Reply button (right)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF334155).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left icons
                      _buildToolbarIcon(
                        Icons.image,
                        onTap: widget.onImageTap,
                      ),
                      const SizedBox(width: 16),
                      _buildToolbarIcon(
                        Icons.gif_box,
                        onTap: widget.onGifTap,
                      ),
                      const SizedBox(width: 16),
                      _buildToolbarIcon(
                        Icons.face,
                        onTap: widget.onStickerTap,
                      ),
                      
                      const Spacer(),
                      
                      // Reply button
                      ElevatedButton(
                        onPressed: _controller.text.trim().isEmpty
                            ? null
                            : _handleReply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF136DEC), // Blue
                          disabledBackgroundColor: const Color(0xFF136DEC)
                              .withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white
                              .withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: const Color(0xFF136DEC), // Blue
          size: 24,
        ),
      ),
    );
  }
}

/// Helper function to show the reply composer as a modal bottom sheet
void showReplyComposer({
  required BuildContext context,
  required WallPost post,
  VoidCallback? onImageTap,
  VoidCallback? onGifTap,
  VoidCallback? onStickerTap,
  Function(String content)? onReply,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ReplyComposerWidget(
        post: post,
        onImageTap: onImageTap,
        onGifTap: onGifTap,
        onStickerTap: onStickerTap,
        onReply: onReply,
      ),
      fullscreenDialog: true,
    ),
  );
}
