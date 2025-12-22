import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../providers/community_chat_room_provider.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(NeoSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: NeoSpacing.md),
              Text(
                'No hay salas públicas',
                style: NeoTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: NeoSpacing.sm),
              Text(
                'Las salas aparecerán aquí cuando se creen',
                style: NeoTextStyles.bodyMedium.copyWith(
                  color: NeoColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
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
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    WidgetRef ref,
    CommunityChatRoomEntity room,
  ) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to room or show join dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unirse a "${room.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeoColors.card,
              NeoColors.card.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NeoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room icon
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
                    color: NeoColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatMemberCount(room.memberCount),
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: NeoColors.textTertiary,
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
    );
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
