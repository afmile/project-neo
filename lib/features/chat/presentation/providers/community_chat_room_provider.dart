import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../../data/models/community_chat_room_model.dart';
import '../../data/repositories/chat_channel_repository.dart';

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
      error: error,
    );
  }
}

/// Notifier for community chat rooms - NOW USING SUPABASE
class CommunityChatRoomNotifier extends StateNotifier<CommunityChatRoomState> {
  final String communityId;
  final ChatChannelRepository _repository;

  CommunityChatRoomNotifier(this.communityId, {ChatChannelRepository? repository})
      : _repository = repository ?? ChatChannelRepository(),
        super(const CommunityChatRoomState()) {
    _loadRoomsFromSupabase();
  }

  /// Load rooms from Supabase (replaces _loadMockRooms)
  Future<void> _loadRoomsFromSupabase() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final rooms = await _repository.fetchChannels(communityId);
      state = state.copyWith(
        rooms: rooms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cargar salas: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Create a new chat channel
  Future<bool> createChannel({
    required String title,
    String? description,
    String? iconUrl,
    String? backgroundImageUrl,
    bool voiceEnabled = false,
    bool videoEnabled = false,
    bool projectionEnabled = false,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(error: 'No hay usuario autenticado');
      return false;
    }

    try {
      final newRoom = await _repository.createChannel(
        communityId: communityId,
        creatorId: userId,
        title: title,
        description: description,
        iconUrl: iconUrl,
        backgroundImageUrl: backgroundImageUrl,
        voiceEnabled: voiceEnabled,
        videoEnabled: videoEnabled,
        projectionEnabled: projectionEnabled,
      );

      // Add the new room to the list
      state = state.copyWith(
        rooms: [newRoom, ...state.rooms],
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Error al crear sala: ${e.toString()}');
      return false;
    }
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

  void togglePin(String roomId) async {
    final room = state.rooms.firstWhere((r) => r.id == roomId);
    final newPinned = !room.isPinned;
    int? newOrder;
    
    if (newPinned) {
      // Assign next order
      final maxOrder = getPinnedRooms()
          .map((r) => r.pinnedOrder ?? -1)
          .fold(-1, (max, order) => order > max ? order : max);
      newOrder = maxOrder + 1;
    }

    // Update locally first for immediate feedback
    final rooms = state.rooms.map((r) {
      if (r.id == roomId) {
        return r.copyWith(isPinned: newPinned, pinnedOrder: newOrder);
      }
      return r;
    }).toList();

    state = state.copyWith(rooms: rooms);

    // Then update in Supabase
    try {
      await _repository.togglePin(roomId, newPinned, newOrder);
    } catch (e) {
      // Revert on error
      _loadRoomsFromSupabase();
    }
  }

  void reorderPinned(int oldIndex, int newIndex) {
    final pinned = getPinnedRooms();
    if (oldIndex < 0 || oldIndex >= pinned.length) return;
    if (newIndex < 0 || newIndex >= pinned.length) return;

    // Adjust newIndex when moving forward
    if (oldIndex < newIndex) {
      newIndex -= 1;
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
    _loadRoomsFromSupabase();
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
