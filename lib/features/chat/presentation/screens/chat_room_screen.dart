import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../providers/chat_messages_provider.dart';

/// Chat room screen with realtime messaging and image sharing
class ChatRoomScreen extends ConsumerStatefulWidget {
  final CommunityChatRoomEntity room;

  const ChatRoomScreen({
    super.key,
    required this.room,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  bool _isSending = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(sendMessageProvider).sendMessage(
            channelId: widget.room.id,
            userId: userId,
            content: content,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Read image bytes
      final bytes = await image.readAsBytes();

      // Upload to Supabase Storage
      final imageUrl = await ref.read(sendMessageProvider).uploadChatImage(
            channelId: widget.room.id,
            fileName: image.name,
            fileBytes: bytes,
          );

      // Send message with image
      await ref.read(sendMessageProvider).sendMessage(
            channelId: widget.room.id,
            userId: userId,
            content: '',
            imageUrl: imageUrl,
            type: 'image',
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImageFullscreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.room.id));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          if (widget.room.backgroundImageUrl != null)
            Positioned.fill(
              child: Image.network(
                widget.room.backgroundImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            ),

          // Black overlay
          if (widget.room.backgroundImageUrl != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),

          // Main content
          Column(
            children: [
              // AppBar
              _buildAppBar(),

              // Messages list
              Expanded(
                child: messagesAsync.when(
                  data: (messages) => _buildMessagesList(messages, currentUserId),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: NeoColors.accent),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Error al cargar mensajes',
                      style: NeoTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),

              // Upload indicator
              if (_isUploadingImage)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: NeoColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Subiendo imagen...',
                        style: NeoTextStyles.labelSmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

              // Input bar
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.room.title,
                      style: NeoTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.room.description != null)
                      Text(
                        widget.room.description!,
                        style: NeoTextStyles.labelSmall.copyWith(
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Voice icon if enabled
              if (widget.room.voiceEnabled)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              // Video icon if enabled
              if (widget.room.videoEnabled)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              // Projection icon if enabled
              if (widget.room.projectionEnabled)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.screen_share,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // TODO: Show menu
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessageEntity> messages, String? currentUserId) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Sé el primero en enviar un mensaje!',
              style: NeoTextStyles.bodyLarge.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // Messages are in ascending order, but ListView is reversed
        final message = messages[messages.length - 1 - index];
        final isMine = message.userId == currentUserId;
        final showAvatar = !isMine && (index == messages.length - 1 ||
            messages[messages.length - index].userId != message.userId);

        return _buildMessageBubble(message, isMine, showAvatar);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity message, bool isMine, bool showAvatar) {
    final isImage = message.type == 'image' || message.imageUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for others
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: showAvatar
                  ? CircleAvatar(
                      radius: 16,
                      backgroundColor: NeoColors.accent,
                      child: Text(
                        message.userName?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox(width: 32),
            ),

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Username (for others)
                if (!isMine && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.userName ?? 'Usuario',
                      style: NeoTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Message content (image or text)
                if (isImage)
                  GestureDetector(
                    onTap: () => _showImageFullscreen(message.imageUrl!),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 250,
                        maxHeight: 300,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: NeoColors.accent,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? NeoColors.accent
                          : Colors.grey[800]!.withOpacity(0.9),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMine ? const Radius.circular(18) : const Radius.circular(4),
                        bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      message.content ?? '',
                      style: NeoTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border(
          top: BorderSide(
            color: NeoColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Image attachment button
              IconButton(
                icon: Icon(
                  Icons.add_photo_alternate,
                  color: _isUploadingImage ? Colors.grey : NeoColors.accent,
                ),
                onPressed: _isUploadingImage ? null : _pickAndSendImage,
              ),
              const SizedBox(width: 8),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: NeoColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'ahora';
    }
  }
}

/// Fullscreen image viewer with zoom
class _FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullscreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: NeoColors.accent,
              ),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
