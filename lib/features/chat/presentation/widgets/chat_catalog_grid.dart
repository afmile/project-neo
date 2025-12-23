import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../providers/community_chat_room_provider.dart';
import '../screens/create_chat_screen.dart';
import '../screens/chat_room_screen.dart';

class ChatCatalogGrid extends ConsumerWidget {
  final String communityId;

  const ChatCatalogGrid({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(communityChatRoomProvider(communityId));
    
    // Filter only public rooms for catalog
    final publicRooms = roomState.rooms
        .where((room) => room.type == RoomType.public)
        .toList();

    if (roomState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: NeoColors.accent),
      );
    }

    if (publicRooms.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(NeoSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: NeoSpacing.md,
            mainAxisSpacing: NeoSpacing.md,
          ),
          itemCount: publicRooms.length,
          itemBuilder: (context, index) {
            final room = publicRooms[index];
            return _buildRoomCard(context, ref, room);
          },
        ),
      ],
    );
  }

  void _navigateToCreateChat(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateChatScreen(communityId: communityId),
      ),
    );
    
    if (result == true) {
      ref.read(communityChatRoomProvider(communityId).notifier).refreshRooms();
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NeoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NeoColors.accent.withOpacity(0.2),
                    NeoColors.accent.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: NeoColors.accent.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: NeoSpacing.lg),
            Text(
              'No hay salas de chat activas',
              style: NeoTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: NeoSpacing.sm),
            Text(
              '¡Sé el primero en crear una sala!',
              style: NeoTextStyles.bodyMedium.copyWith(
                color: NeoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateChat(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Crear sala',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    WidgetRef ref,
    CommunityChatRoomEntity room,
  ) {
    final hasBackgroundImage = room.backgroundImageUrl != null && 
                                room.backgroundImageUrl!.isNotEmpty;
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(room: room),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Main card container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              image: hasBackgroundImage
                  ? DecorationImage(
                      image: NetworkImage(room.backgroundImageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    )
                  : null,
              gradient: !hasBackgroundImage
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NeoColors.card,
                        NeoColors.card.withOpacity(0.8),
                      ],
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(NeoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room icon (only show if no background image)
                  if (!hasBackgroundImage)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Room title
                  Text(
                    room.title,
                    style: NeoTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: hasBackgroundImage
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Member count
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: hasBackgroundImage ? Colors.white70 : NeoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatMemberCount(room.memberCount),
                        style: NeoTextStyles.labelSmall.copyWith(
                          color: hasBackgroundImage ? Colors.white70 : NeoColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      // Join indicator
                      Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: NeoColors.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Creator avatar with status ring (Top-left)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getStatusRingColor(room),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: NeoColors.accent,
                backgroundImage: room.creatorAvatarUrl != null
                    ? NetworkImage(room.creatorAvatarUrl!)
                    : null,
                child: room.creatorAvatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get status ring color based on room features
  Color _getStatusRingColor(CommunityChatRoomEntity room) {
    if (room.projectionEnabled) {
      return const Color(0xFFFF073A); // Neon Red for projection
    } else if (room.voiceEnabled) {
      return const Color(0xFF39FF14); // Neon Green for voice
    } else {
      return Colors.transparent; // No ring if both are off
    }
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
