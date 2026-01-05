/// Project Neo - Wall Threads Composer Sheet
///
/// Full Threads-style modal composer with modern multi-image selection
/// - Borderless TextField (text "floats")
/// - Animated preview rail with glassmorphic remove buttons
/// - Haptic feedback on interactions
/// - "Publicar" as text button in header (disabled if empty)
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';

import '../providers/community_members_provider.dart';

class WallThreadsComposerSheet extends StatefulWidget {
  final UserEntity currentUser;
  final UserEntity profileUser;
  final String communityId;
  final bool isSelfProfile;
  final VoidCallback onSuccess;
  
  /// The local community profile of the author (current user)
  final CommunityMember? localProfile;
  
  /// The local community profile of the wall owner
  final CommunityMember? wallOwnerProfile;

  const WallThreadsComposerSheet({
    super.key,
    required this.currentUser,
    required this.profileUser,
    required this.communityId,
    required this.isSelfProfile,
    required this.onSuccess,
    this.localProfile,
    this.wallOwnerProfile,
  });

  @override
  State<WallThreadsComposerSheet> createState() => _WallThreadsComposerSheetState();
}

class _WallThreadsComposerSheetState extends State<WallThreadsComposerSheet>
    with TickerProviderStateMixin {
  // ... existing state variables ...
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  
  bool _isPosting = false;
  final List<XFile> _selectedImages = [];
  static const int _maxImages = 10;

  @override
  void initState() {
    super.initState();
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

  // ... _pickImages and _removeImage methods remain the same ...
  Future<void> _pickImages() async {
    final hadFocus = _focusNode.hasFocus;
    try {
      final int remainingSlots = _maxImages - _selectedImages.length;
      if (remainingSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Máximo 10 imágenes permitidas'),
            backgroundColor: NeoColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        HapticFeedback.lightImpact();
        setState(() {
          final imagesToAdd = images.take(remainingSlots).toList();
          _selectedImages.addAll(imagesToAdd);
        });
        
        if (images.length > remainingSlots) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solo se agregaron $remainingSlots imágenes (límite: $_maxImages)'),
              backgroundColor: NeoColors.warning,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
    if (hadFocus && mounted) {
      _focusNode.requestFocus();
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handlePost() async {
    if (!_canPost) return;

    setState(() => _isPosting = true);

    try {
      // Debug: Log initial state
      print('🟡 DEBUG: ========== INICIANDO PUBLICACIÓN ==========');
      print('🟡 DEBUG: currentUser.id: ${widget.currentUser.id}');
      print('🟡 DEBUG: profileUser.id: ${widget.profileUser.id}');
      print('🟡 DEBUG: communityId: ${widget.communityId}');
      print('🟡 DEBUG: isSelfProfile: ${widget.isSelfProfile}');
      print('🟡 DEBUG: content: "${_textController.text.trim()}"');
      
      // WallThreadsComposerSheet is ONLY used for profile walls
      // ALWAYS insert to profile_wall_posts (whether own or other's profile)
      print('🟢 DEBUG: Insertando en profile_wall_posts (contexto de perfil)');
      
      final payload = {
        'profile_user_id': widget.profileUser.id,  // Profile wall owner
        'author_id': widget.currentUser.id,         // Post author
        'community_id': widget.communityId,
        'content': _textController.text.trim(),
      };
      print('🟡 DEBUG: Payload: $payload');
      
      final result = await Supabase.instance.client
          .from('profile_wall_posts')
          .insert(payload);
      
      print('🟢 DEBUG: Insert exitoso: $result');
      print('🟢 DEBUG: ========== PUBLICACIÓN COMPLETADA ==========');

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
    } catch (e, stackTrace) {
      print('🔴 DEBUG: ========== ERROR EN PUBLICACIÓN ==========');
      print('🔴 DEBUG: Error: $e');
      print('🔴 DEBUG: StackTrace: $stackTrace');
      
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
                _buildHeader(),
                Container(
                  height: 0.5,
                  color: Colors.grey[900],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAuthorInfo(),
                        const SizedBox(height: 16),
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
                _buildImagePreviewRail(),
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
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Nuevo post',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    // Identity Logic:
    // 1. Try Local Community Profile (Nickname/Avatar) from CommunityMember object
    // 2. Fallback to Global User Data (Username/Avatar)
    
    final displayName = widget.localProfile?.username ?? widget.currentUser.username;
    final avatarUrl = widget.localProfile?.avatarUrl ?? widget.currentUser.avatarUrl;
    
    // Profile User Logic (Wall Owner):
    final profileUserNickname = widget.wallOwnerProfile?.username ?? widget.profileUser.username;
    
    final profileDisplayName = widget.isSelfProfile 
        ? 'tu muro'
        : 'el muro de $profileUserNickname';
    
    final contextText = 'Publicando en $profileDisplayName';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  /// Animated horizontal preview rail for selected images
  Widget _buildImagePreviewRail() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _selectedImages.isEmpty
          ? const SizedBox.shrink()
          : Container(
              height: 116, // 100px thumbnail + 8px padding top/bottom
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[900]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return _buildImageThumbnail(index);
                },
              ),
            ),
    );
  }

  /// Individual thumbnail with animated entrance and glassmorphic remove button
  Widget _buildImageThumbnail(int index) {
    final image = _selectedImages[index];
    
    return TweenAnimationBuilder<double>(
      key: ValueKey(image.path),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(image.path),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            
            // Glassmorphic remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
          // Image button - fully enabled
          _buildActionIcon(
            Icons.image_outlined,
            onTap: _pickImages,
            badge: _selectedImages.isNotEmpty ? _selectedImages.length : null,
          ),
          const SizedBox(width: 20),
          _buildActionIcon(Icons.gif_box_outlined),
          const SizedBox(width: 20),
          _buildActionIcon(Icons.emoji_emotions_outlined),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, {VoidCallback? onTap, int? badge}) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: isEnabled ? NeoColors.accent : Colors.grey[600],
            size: 24,
          ),
          // Badge for image count
          if (badge != null)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: NeoColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
