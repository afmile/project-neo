/// Project Neo - Bento Post Composer
///
/// Modern composer for creating posts with media support
library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/community_members_provider.dart';

class BentoPostComposer extends StatefulWidget {
  final UserEntity currentUser;
  final String communityId;
  final String? profileUserId; // If posting on profile wall
  final Function(String content, String? mediaUrl, String? mediaType) onPost;
  
  const BentoPostComposer({
    super.key,
    required this.currentUser,
    required this.communityId,
    this.profileUserId,
    required this.onPost,
  });

  @override
  State<BentoPostComposer> createState() => _BentoPostComposerState();
}

class _BentoPostComposerState extends State<BentoPostComposer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  
  bool _isPosting = false;
  String? _selectedMediaPath;
  String? _selectedMediaType; // 'image' or 'gif'
  CommunityMember? _currentMember; // Local community profile
  bool _isLoadingMember = true;

  @override
  void initState() {
    super.initState();
    // Fetch local community member profile
    _fetchLocalMember();
    // Auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _fetchLocalMember() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = widget.currentUser.id;
      
      final response = await supabase
          .from('community_members')
          .select('''
            user_id, role, joined_at, nickname, avatar_url, is_leader, is_moderator,
            users_global!inner(username, avatar_global_url)
          ''')
          .eq('user_id', userId)
          .eq('community_id', widget.communityId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null && mounted) {
        final userData = response['users_global'] as Map<String, dynamic>?;
        final globalUsername = userData?['username'] as String? ?? 'Usuario';
        final globalAvatar = userData?['avatar_global_url'] as String?;

        final displayName = response['nickname'] as String? ?? globalUsername;
        final displayAvatar = response['avatar_url'] as String? ?? globalAvatar;

        setState(() {
          _currentMember = CommunityMember(
            id: response['user_id'] as String,
            username: displayName,
            nickname: response['nickname'] as String?,
            avatarUrl: displayAvatar,
            role: response['role'] as String? ?? 'member',
            joinedAt: DateTime.tryParse(response['joined_at'] as String? ?? '') ?? DateTime.now(),
          );
          _isLoadingMember = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingMember = false);
      }
    } catch (e) {
      print('❌ Error fetching local member: $e');
      if (mounted) {
        setState(() => _isLoadingMember = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canPost => _textController.text.trim().isNotEmpty && !_isPosting;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedMediaPath = image.path;
          _selectedMediaType = 'image';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error seleccionando imagen: $e'),
          backgroundColor: NeoColors.error,
        ),
      );
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMediaPath = null;
      _selectedMediaType = null;
    });
  }

  Future<void> _handlePost() async {
    if (!_canPost) return;

    setState(() => _isPosting = true);

    try {
      // TODO: Upload media to Supabase Storage if exists
      // For now, pass null for mediaUrl
      await widget.onPost(
        _textController.text.trim(),
        null, // Will be implemented: uploaded mediaUrl
        _selectedMediaType,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isPosting = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error publicando: $e'),
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
                // Header
                _buildHeader(),
                
                // Divider
                Container(
                  height: 0.5,
                  color: Colors.grey[900],
                ),
                
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author info
                        _buildAuthorInfo(),
                        
                        const SizedBox(height: 16),
                        
                        // Media preview (if exists)
                        if (_selectedMediaPath != null) ...[
                          _buildMediaPreview(),
                          const SizedBox(height: 16),
                        ],
                        
                        // Text field
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
                
                // Footer
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
            
            // Publish button
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
    final contextText = widget.profileUserId != null
        ? 'Publicando en muro de perfil'
        : 'Publicando en muro de comunidad';

    // Use local community identity if loaded, otherwise fallback to global
    final displayName = _currentMember?.username ?? widget.currentUser.username;
    final displayAvatar = _currentMember?.avatarUrl ?? widget.currentUser.avatarUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: NeoColors.accent.withValues(alpha: 0.15),
          backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
              ? NetworkImage(displayAvatar)
              : null,
          child: displayAvatar == null || displayAvatar.isEmpty
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
              Row(
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (_isLoadingMember) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
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

  Widget _buildMediaPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              _selectedMediaPath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[850],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: _removeMedia,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
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
          _buildActionIcon(Icons.image_outlined, 'Imagen', _pickImage),
          const SizedBox(width: 20),
          _buildActionIcon(Icons.gif_box_outlined, 'GIF', null),
          const SizedBox(width: 20),
          _buildActionIcon(Icons.emoji_emotions_outlined, 'Emoji', null),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback? onTap) {
    final isEnabled = onTap != null;
    
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: isEnabled ? NeoColors.accent : Colors.grey[700],
          size: 24,
        ),
      ),
    );
  }
}
