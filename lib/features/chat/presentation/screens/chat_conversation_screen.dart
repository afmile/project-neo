import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/chat_entity.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  final ChatEntity chat;

  const ChatConversationScreen({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Mock messages for demonstration
  final List<_MockMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMockMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMockMessages() {
    final now = DateTime.now();
    
    _messages.addAll([
      _MockMessage(
        id: '1',
        content: 'Hola! ¿Cómo estás?',
        isMine: false,
        timestamp: now.subtract(const Duration(hours: 2)),
        senderName: widget.chat.participants.isNotEmpty 
            ? widget.chat.participants.first.username 
            : 'Usuario',
      ),
      _MockMessage(
        id: '2',
        content: 'Todo bien! ¿Y tú?',
        isMine: true,
        timestamp: now.subtract(const Duration(hours: 2, minutes: -5)),
        senderName: 'Tú',
      ),
      _MockMessage(
        id: '3',
        content: widget.chat.lastMessage?.content ?? 'Mensaje de prueba',
        isMine: false,
        timestamp: widget.chat.lastMessageTime,
        senderName: widget.chat.participants.isNotEmpty 
            ? widget.chat.participants.first.username 
            : 'Usuario',
      ),
    ]);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        _MockMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _messageController.text.trim(),
          isMine: true,
          timestamp: DateTime.now(),
          senderName: 'Tú',
        ),
      );
    });

    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildMessagesList(),
          ),
          
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
              border: Border.all(color: Colors.white10, width: 1),
            ),
            child: ClipOval(
              child: widget.chat.avatarUrl != null
                  ? Image.network(
                      widget.chat.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.title,
                  style: NeoTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.chat.type == ChatType.publicRoomJoined && 
                    widget.chat.communityName != null)
                  Text(
                    widget.chat.communityName!,
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: NeoColors.textSecondary,
                    ),
                  )
                else if (widget.chat.isGroup)
                  Text(
                    '${widget.chat.participants.length} miembros',
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: NeoColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    'En línea',
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: NeoColors.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Call button (disabled)
        IconButton(
          icon: Icon(
            Icons.call_rounded,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          onPressed: null,
        ),
        // Video call button (disabled)
        IconButton(
          icon: Icon(
            Icons.videocam_rounded,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          onPressed: null,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    IconData icon;
    switch (widget.chat.type) {
      case ChatType.privateOneOnOne:
        icon = Icons.person;
        break;
      case ChatType.privateGroup:
        icon = Icons.group;
        break;
      case ChatType.publicRoomJoined:
        icon = Icons.people_outline;
        break;
    }

    return Icon(
      icon,
      color: Colors.white54,
      size: 24,
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(NeoSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(_MockMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NeoSpacing.md),
      child: Row(
        mainAxisAlignment: message.isMine 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users (left side)
          if (!message.isMine && widget.chat.isGroup) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white54,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMine 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Sender name for group chats
                if (!message.isMine && widget.chat.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: NeoTextStyles.labelSmall.copyWith(
                        color: NeoColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isMine 
                        ? NeoColors.accent 
                        : Colors.grey[850],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isMine ? 20 : 4),
                      bottomRight: Radius.circular(message.isMine ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: NeoTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: NeoColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Spacing for alignment
          if (message.isMine && widget.chat.isGroup)
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(NeoSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Emoji button
            IconButton(
              icon: const Icon(
                Icons.emoji_emotions_outlined,
                color: NeoColors.textSecondary,
              ),
              onPressed: () {
                // TODO: Show emoji picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emojis - Próximamente'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: NeoTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: NeoTextStyles.bodyMedium.copyWith(
                      color: NeoColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Attach button
            IconButton(
              icon: const Icon(
                Icons.attach_file_rounded,
                color: NeoColors.textSecondary,
              ),
              onPressed: () {
                // TODO: Show attachment options
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Adjuntar - Próximamente'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Mock message class for demonstration
class _MockMessage {
  final String id;
  final String content;
  final bool isMine;
  final DateTime timestamp;
  final String senderName;

  _MockMessage({
    required this.id,
    required this.content,
    required this.isMine,
    required this.timestamp,
    required this.senderName,
  });
}
