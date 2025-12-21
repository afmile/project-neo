
import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for chats
    final chats = [
      _ChatModel(
        title: 'Sala de Proyección',
        communityName: 'Anime Fans',
        lastMessage: '¿A qué hora empieza la película?',
        time: '14:30',
        communityImage: null, // Placeholder will be used
        avatarImage: null,
      ),
      _ChatModel(
        title: 'Dudas y Soporte',
        communityName: 'Neo Official',
        lastMessage: 'Gracias por el reporte, lo revisaremos.',
        time: '12:15',
        communityImage: null,
        avatarImage: null,
      ),
      _ChatModel(
        title: 'JuanPerez',
        communityName: 'Gaming Zone',
        lastMessage: 'Sale una partida de LoL?',
        time: 'Ayer',
        communityImage: null,
        avatarImage: null,
        isPrivate: true,
      ),
       _ChatModel(
        title: 'Rolplay Medieval',
        communityName: 'Roleplay Amino',
        lastMessage: '*Desenvaina su espada* ¡Prepárate!',
        time: 'Ayer',
        communityImage: null,
        avatarImage: null,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(NeoSpacing.md),
          itemCount: chats.length,
          separatorBuilder: (context, index) => const SizedBox(height: NeoSpacing.sm),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return _ChatListItem(chat: chat);
          },
        ),
      ),
    );
  }
}

class _ChatModel {
  final String title;
  final String communityName;
  final String lastMessage;
  final String time;
  final String? communityImage;
  final String? avatarImage;
  final bool isPrivate;

  _ChatModel({
    required this.title,
    required this.communityName,
    required this.lastMessage,
    required this.time,
    this.communityImage,
    this.avatarImage,
    this.isPrivate = false,
  });
}

class _ChatListItem extends StatelessWidget {
  final _ChatModel chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NeoSpacing.md),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Leading Stack
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              children: [
                // Community Image (Main)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[800],
                     border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: const Icon(Icons.people_outline, color: Colors.white54),
                ),
                // Small overlay icon/avatar (Bottom Right)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NeoColors.card, // Border effect
                      border: Border.all(color: NeoColors.card, width: 2),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: NeoColors.accent,
                      ),
                      child: Icon(
                        chat.isPrivate ? Icons.person : Icons.tag,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NeoSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.title,
                  style: NeoTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      chat.communityName,
                      style: NeoTextStyles.labelSmall.copyWith(
                        color: NeoColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '• ${chat.lastMessage}',
                        style: NeoTextStyles.bodySmall.copyWith(
                           color: NeoColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: NeoSpacing.sm),
          // Time
          Text(
            chat.time,
            style: NeoTextStyles.labelSmall.copyWith(
              color: NeoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
