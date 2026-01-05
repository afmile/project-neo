/// Project Neo - Wall Threads Composer Sheet
///
/// Full Threads-style modal composer
/// - Borderless TextField (text "floats")
/// - "Publicar" as text button in header (disabled if empty)
/// - Clean, minimal, social app aesthetic
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';

class WallThreadsComposerSheet extends StatefulWidget {
  final UserEntity currentUser;
  final UserEntity profileUser;
  final String communityId;
  final bool isSelfProfile;
  final VoidCallback onSuccess;
  final String? localNickname;
  final String? localAvatarUrl;

  const WallThreadsComposerSheet({
    super.key,
    required this.currentUser,
    required this.profileUser,
    required this.communityId,
    required this.isSelfProfile,
    required this.onSuccess,
    this.localNickname,
    this.localAvatarUrl,
  });

  @override
  State<WallThreadsComposerSheet> createState() => _WallThreadsComposerSheetState();
}

class _WallThreadsComposerSheetState extends State<WallThreadsComposerSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canPost => _textController.text.trim().isNotEmpty && !_isPosting;

  Future<void> _handlePost() async {
    if (!_canPost) return;

    setState(() => _isPosting = true);

    try {
      await Supabase.instance.client.from('profile_wall_posts').insert({
        'profile_user_id': widget.profileUser.id,
        'author_id': widget.currentUser.id,
        'community_id': widget.communityId,
        'content': _textController.text.trim(),
      });

      if (!mounted) return;
      
      Navigator.pop(context);
      widget.onSuccess();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isPosting = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: NeoColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header - 56dp
                _buildHeader(),
                
                // Subtle divider
                Container(
                  height: 0.5,
                  color: Colors.grey[900],
                ),
                
                // Body - scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author info + context
                        _buildAuthorInfo(),
                        
                        const SizedBox(height: 16),
                        
                        // TextField - NO BORDERS, text "floats"
                        TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          minLines: 5,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: NeoColors.accent,
                          cursorWidth: 2,
                          cursorHeight: 20,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.4,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: const InputDecoration(
                            hintText: '¿Qué quieres compartir?',
                            hintStyle: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            filled: false,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer - attachment actions
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            
            // Title
            const Text(
              'Nuevo post',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // "Publicar" text button
            _isPosting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: NeoColors.accent,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _canPost ? _handlePost : null,
                    child: Text(
                      'Publicar',
                      style: TextStyle(
                        color: _canPost ? NeoColors.accent : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorInfo() {
    // Use local nickname if available, otherwise fallback to global username
    final displayName = widget.localNickname ?? widget.currentUser.username;
    final avatarUrl = widget.localAvatarUrl ?? widget.currentUser.avatarUrl;
    
    final contextText = widget.isSelfProfile
        ? 'Publicando en tu muro'
        : 'Publicando en el muro de ${widget.profileUser.username}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar - 36dp
        CircleAvatar(
          radius: 18,
          backgroundColor: NeoColors.accent.withValues(alpha: 0.15),
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: NeoColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        
        // Name + context
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                contextText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[900]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildActionIcon(Icons.image_outlined),
          const SizedBox(width: 20),
          _buildActionIcon(Icons.gif_box_outlined),
          const SizedBox(width: 20),
          _buildActionIcon(Icons.emoji_emotions_outlined),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Opacity(
      opacity: 0.4, // Placeholder - disabled for now
      child: Icon(
        icon,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
}
