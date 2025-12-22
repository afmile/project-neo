import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../../data/models/community_chat_room_model.dart';

/// State for community chat rooms
class CommunityChatRoomState {
  final List<CommunityChatRoomEntity> rooms;
  final bool isLoading;
  final String? error;

  const CommunityChatRoomState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });

  CommunityChatRoomState copyWith({
    List<CommunityChatRoomEntity>? rooms,
    bool? isLoading,
    String? error,
  }) {
    return CommunityChatRoomState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for community chat rooms
class CommunityChatRoomNotifier extends StateNotifier<CommunityChatRoomState> {
  final String communityId;

  CommunityChatRoomNotifier(this.communityId)
      : super(const CommunityChatRoomState()) {
    _loadMockRooms();
  }

  void _loadMockRooms() {
    state = state.copyWith(isLoading: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      final mockRooms = _generateMockRooms();
      state = state.copyWith(
        rooms: mockRooms,
        isLoading: false,
      );
    });
  }

  List<CommunityChatRoomEntity> _generateMockRooms() {
    final now = DateTime.now();

    return [
      // Pinned room 1
      CommunityChatRoomModel(
        id: 'room_1',
        communityId: communityId,
        type: RoomType.public,
        title: 'Sala General',
        description: 'Chat general de la comunidad',
        memberCount: 1234,
        lastMessage: RoomMessageModel(
          id: 'msg_1',
          senderId: 'user_1',
          senderName: 'María',
          content: '¡Hola a todos!',
          timestamp: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(minutes: 5)),
        lastUserActivity: now.subtract(const Duration(minutes: 5)),
        unreadCount: 5,
        isPinned: true,
        pinnedOrder: 0,
        isFavorite: true,
      ),

      // Pinned room 2
      CommunityChatRoomModel(
        id: 'room_2',
        communityId: communityId,
        type: RoomType.public,
        title: 'Roleplay',
        description: 'Sala de roleplay',
        memberCount: 567,
        lastMessage: RoomMessageModel(
          id: 'msg_2',
          senderId: 'user_2',
          senderName: 'Carlos',
          content: '*Se acerca lentamente*',
          timestamp: now.subtract(const Duration(hours: 1)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 1)),
        lastUserActivity: now.subtract(const Duration(hours: 2)),
        unreadCount: 2,
        isPinned: true,
        pinnedOrder: 1,
        isFavorite: false,
      ),

      // Pinned room 3
      CommunityChatRoomModel(
        id: 'room_3',
        communityId: communityId,
        type: RoomType.public,
        title: 'Arte y Creatividad',
        description: 'Comparte tus creaciones',
        memberCount: 890,
        lastMessage: RoomMessageModel(
          id: 'msg_3',
          senderId: 'user_3',
          senderName: 'Ana',
          content: 'Miren mi nuevo dibujo!',
          timestamp: now.subtract(const Duration(hours: 3)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 3)),
        lastUserActivity: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
        isPinned: true,
        pinnedOrder: 2,
        isFavorite: false,
      ),

      // Pinned room 4
      CommunityChatRoomModel(
        id: 'room_8',
        communityId: communityId,
        type: RoomType.public,
        title: 'Música y Podcasts',
        description: 'Comparte tu música favorita',
        memberCount: 678,
        lastMessage: RoomMessageModel(
          id: 'msg_8',
          senderId: 'user_8',
          senderName: 'Pedro',
          content: '🎵 Escuchen esta canción!',
          timestamp: now.subtract(const Duration(minutes: 45)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(minutes: 45)),
        lastUserActivity: now.subtract(const Duration(hours: 1)),
        unreadCount: 8,
        isPinned: true,
        pinnedOrder: 3,
        isFavorite: true,
      ),

      // Pinned room 5
      CommunityChatRoomModel(
        id: 'room_9',
        communityId: communityId,
        type: RoomType.public,
        title: 'Gaming Zone',
        description: 'Para los gamers de la comunidad',
        memberCount: 1456,
        lastMessage: RoomMessageModel(
          id: 'msg_9',
          senderId: 'user_9',
          senderName: 'Alex',
          content: 'Alguien para jugar?',
          timestamp: now.subtract(const Duration(minutes: 15)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(minutes: 15)),
        lastUserActivity: now.subtract(const Duration(minutes: 15)),
        unreadCount: 12,
        isPinned: true,
        pinnedOrder: 4,
        isFavorite: false,
      ),

      // Unpinned room 1 (recent user activity)
      CommunityChatRoomModel(
        id: 'room_4',
        communityId: communityId,
        type: RoomType.public,
        title: 'Dudas y Soporte',
        description: 'Ayuda de la comunidad',
        memberCount: 456,
        lastMessage: RoomMessageModel(
          id: 'msg_4',
          senderId: 'user_4',
          senderName: 'Luis',
          content: '¿Alguien sabe cómo...?',
          timestamp: now.subtract(const Duration(minutes: 30)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(minutes: 30)),
        lastUserActivity: now.subtract(const Duration(minutes: 30)),
        unreadCount: 3,
        isPinned: false,
        isFavorite: false,
      ),

      // Unpinned room 2
      CommunityChatRoomModel(
        id: 'room_5',
        communityId: communityId,
        type: RoomType.public,
        title: 'Off-Topic',
        description: 'Conversación libre',
        memberCount: 789,
        lastMessage: RoomMessageModel(
          id: 'msg_5',
          senderId: 'user_5',
          senderName: 'Sofia',
          content: 'Jajaja',
          timestamp: now.subtract(const Duration(hours: 2)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        lastUserActivity: now.subtract(const Duration(hours: 4)),
        unreadCount: 0,
        isPinned: false,
        isFavorite: false,
      ),

      // Unpinned room 3 (private)
      CommunityChatRoomModel(
        id: 'room_6',
        communityId: communityId,
        type: RoomType.private,
        title: 'Equipo de Moderación',
        description: 'Chat privado de mods',
        memberCount: 5,
        lastMessage: RoomMessageModel(
          id: 'msg_6',
          senderId: 'mod_1',
          senderName: 'Moderador',
          content: 'Revisemos los reportes.',
          timestamp: now.subtract(const Duration(hours: 6)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 6)),
        lastUserActivity: now.subtract(const Duration(days: 2)),
        unreadCount: 0,
        isPinned: false,
        isFavorite: false,
      ),

      // Unpinned room 4
      CommunityChatRoomModel(
        id: 'room_7',
        communityId: communityId,
        type: RoomType.public,
        title: 'Eventos',
        description: 'Organización de eventos',
        memberCount: 234,
        lastMessage: RoomMessageModel(
          id: 'msg_7',
          senderId: 'user_7',
          senderName: 'Diego',
          content: 'El evento es el sábado!',
          timestamp: now.subtract(const Duration(days: 1)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(days: 1)),
        lastUserActivity: now.subtract(const Duration(days: 3)),
        unreadCount: 0,
        isPinned: false,
        isFavorite: false,
      ),

      // Unpinned room 5
      CommunityChatRoomModel(
        id: 'room_10',
        communityId: communityId,
        type: RoomType.public,
        title: 'Memes y Humor',
        description: 'Comparte memes divertidos',
        memberCount: 2345,
        lastMessage: RoomMessageModel(
          id: 'msg_10',
          senderId: 'user_10',
          senderName: 'Laura',
          content: '😂😂😂',
          timestamp: now.subtract(const Duration(hours: 5)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 5)),
        lastUserActivity: now.subtract(const Duration(hours: 8)),
        unreadCount: 0,
        isPinned: false,
        isFavorite: false,
      ),

      // Unpinned room 6
      CommunityChatRoomModel(
        id: 'room_11',
        communityId: communityId,
        type: RoomType.public,
        title: 'Deportes',
        description: 'Hablemos de deportes',
        memberCount: 567,
        lastMessage: RoomMessageModel(
          id: 'msg_11',
          senderId: 'user_11',
          senderName: 'Roberto',
          content: 'Qué partidazo!',
          timestamp: now.subtract(const Duration(hours: 12)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 12)),
        lastUserActivity: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
        isPinned: false,
        isFavorite: false,
      ),

      // Unpinned room 7
      CommunityChatRoomModel(
        id: 'room_12',
        communityId: communityId,
        type: RoomType.public,
        title: 'Cine y Series',
        description: 'Recomendaciones y spoilers',
        memberCount: 1123,
        lastMessage: RoomMessageModel(
          id: 'msg_12',
          senderId: 'user_12',
          senderName: 'Camila',
          content: 'Vieron el último episodio?',
          timestamp: now.subtract(const Duration(days: 2)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(days: 2)),
        lastUserActivity: now.subtract(const Duration(days: 4)),
        unreadCount: 0,
        isPinned: false,
        isFavorite: false,
      ),
    ];
  }

  // Get pinned rooms sorted by pinnedOrder
  List<CommunityChatRoomEntity> getPinnedRooms() {
    final pinned = state.rooms.where((room) => room.isPinned).toList();
    pinned.sort((a, b) {
      if (a.pinnedOrder == null) return 1;
      if (b.pinnedOrder == null) return -1;
      return a.pinnedOrder!.compareTo(b.pinnedOrder!);
    });
    return pinned;
  }

  // Get unpinned rooms sorted by lastUserActivity
  List<CommunityChatRoomEntity> getUnpinnedRooms() {
    final unpinned = state.rooms.where((room) => !room.isPinned).toList();
    unpinned.sort((a, b) {
      if (a.lastUserActivity == null) return 1;
      if (b.lastUserActivity == null) return -1;
      return b.lastUserActivity!.compareTo(a.lastUserActivity!);
    });
    return unpinned;
  }

  void togglePin(String roomId) {
    final rooms = state.rooms.map((room) {
      if (room.id == roomId) {
        if (room.isPinned) {
          // Unpin
          return room.copyWith(isPinned: false, pinnedOrder: null);
        } else {
          // Pin - assign next order
          final maxOrder = getPinnedRooms()
              .map((r) => r.pinnedOrder ?? -1)
              .fold(-1, (max, order) => order > max ? order : max);
          return room.copyWith(isPinned: true, pinnedOrder: maxOrder + 1);
        }
      }
      return room;
    }).toList();

    state = state.copyWith(rooms: rooms);
  }

  void reorderPinned(int oldIndex, int newIndex) {
    final pinned = getPinnedRooms();
    if (oldIndex < 0 || oldIndex >= pinned.length) return;
    if (newIndex < 0 || newIndex >= pinned.length) return;

    // CRITICAL FIX: Adjust newIndex when moving forward
    if (oldIndex < newIndex) {
      newIndex -= 1; // Account for removal of original item
    }

    final item = pinned.removeAt(oldIndex);
    pinned.insert(newIndex, item);

    // Update pinnedOrder for all pinned rooms
    final updatedRooms = state.rooms.map((room) {
      if (room.isPinned) {
        final index = pinned.indexWhere((r) => r.id == room.id);
        return room.copyWith(pinnedOrder: index);
      }
      return room;
    }).toList();

    state = state.copyWith(rooms: updatedRooms);
  }

  void toggleFavorite(String roomId) {
    final rooms = state.rooms.map((room) {
      if (room.id == roomId) {
        return room.copyWith(isFavorite: !room.isFavorite);
      }
      return room;
    }).toList();

    state = state.copyWith(rooms: rooms);
  }

  void refreshRooms() {
    _loadMockRooms();
  }
}

/// Provider for community chat rooms
final communityChatRoomProvider = StateNotifierProvider.family<
    CommunityChatRoomNotifier, CommunityChatRoomState, String>(
  (ref, communityId) {
    return CommunityChatRoomNotifier(communityId);
  },
);

/// Provider for pinned rooms
final pinnedRoomsProvider =
    Provider.family<List<CommunityChatRoomEntity>, String>((ref, communityId) {
  final state = ref.watch(communityChatRoomProvider(communityId));
  final pinned = state.rooms.where((room) => room.isPinned).toList();
  pinned.sort((a, b) {
    if (a.pinnedOrder == null) return 1;
    if (b.pinnedOrder == null) return -1;
    return a.pinnedOrder!.compareTo(b.pinnedOrder!);
  });
  return pinned;
});

/// Provider for unpinned rooms
final unpinnedRoomsProvider =
    Provider.family<List<CommunityChatRoomEntity>, String>((ref, communityId) {
  final state = ref.watch(communityChatRoomProvider(communityId));
  final unpinned = state.rooms.where((room) => !room.isPinned).toList();
  unpinned.sort((a, b) {
    if (a.lastUserActivity == null) return 1;
    if (b.lastUserActivity == null) return -1;
    return b.lastUserActivity!.compareTo(a.lastUserActivity!);
  });
  return unpinned;
});
