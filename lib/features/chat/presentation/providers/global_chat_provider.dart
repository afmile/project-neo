import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/global_chat_entity.dart';
import '../../data/models/global_chat_model.dart';

/// State for global chats
class GlobalChatState {
  final List<GlobalChatEntity> chats;
  final bool isLoading;
  final String? error;

  const GlobalChatState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
  });

  GlobalChatState copyWith({
    List<GlobalChatEntity>? chats,
    bool? isLoading,
    String? error,
  }) {
    return GlobalChatState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for global chats
class GlobalChatNotifier extends StateNotifier<GlobalChatState> {
  GlobalChatNotifier() : super(const GlobalChatState()) {
    _loadMockChats();
  }

  void _loadMockChats() {
    state = state.copyWith(isLoading: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      final mockChats = _generateMockChats();
      state = state.copyWith(
        chats: mockChats,
        isLoading: false,
      );
    });
  }

  List<GlobalChatEntity> _generateMockChats() {
    final now = DateTime.now();

    return [
      // Support chat
      GlobalChatModel(
        id: 'support_1',
        source: ChatSource.support,
        title: 'Soporte Neo',
        lastMessage: GlobalChatMessageModel(
          id: 'msg_s1',
          senderId: 'support_team',
          senderName: 'Equipo de Soporte',
          content: '¿Cómo podemos ayudarte hoy?',
          timestamp: now.subtract(const Duration(hours: 3)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 3)),
        unreadCount: 0,
        isFavorite: true,
      ),

      // Moderator chat
      GlobalChatModel(
        id: 'mod_1',
        source: ChatSource.moderator,
        title: 'Moderador Ana',
        lastMessage: GlobalChatMessageModel(
          id: 'msg_m1',
          senderId: 'mod_ana',
          senderName: 'Ana',
          content: 'Gracias por el reporte, lo revisaremos.',
          timestamp: now.subtract(const Duration(days: 1)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
        isFavorite: true,
      ),

      // Community favorite 1
      GlobalChatModel(
        id: 'fav_1',
        source: ChatSource.communityFavorite,
        title: 'Sala General',
        communityId: 'community_1',
        communityName: 'Anime Fans',
        lastMessage: GlobalChatMessageModel(
          id: 'msg_f1',
          senderId: 'user_123',
          senderName: 'Carlos',
          content: '¿Alguien vio el último episodio?',
          timestamp: now.subtract(const Duration(minutes: 15)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(minutes: 15)),
        unreadCount: 3,
        isFavorite: true,
      ),

      // Community favorite 2
      GlobalChatModel(
        id: 'fav_2',
        source: ChatSource.communityFavorite,
        title: 'Dudas y Soporte',
        communityId: 'community_2',
        communityName: 'Neo Official',
        lastMessage: GlobalChatMessageModel(
          id: 'msg_f2',
          senderId: 'admin_1',
          senderName: 'Admin',
          content: 'Hemos actualizado las reglas.',
          timestamp: now.subtract(const Duration(hours: 5)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 5)),
        unreadCount: 0,
        isFavorite: true,
      ),

      // Community favorite 3
      GlobalChatModel(
        id: 'fav_3',
        source: ChatSource.communityFavorite,
        title: 'Roleplay Medieval',
        communityId: 'community_3',
        communityName: 'Roleplay Amino',
        lastMessage: GlobalChatMessageModel(
          id: 'msg_f3',
          senderId: 'user_456',
          senderName: 'Elena',
          content: '*Desenvaina su espada*',
          timestamp: now.subtract(const Duration(hours: 12)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 12)),
        unreadCount: 7,
        isFavorite: true,
      ),
    ];
  }

  void unfavoriteChat(String chatId) {
    state = state.copyWith(
      chats: state.chats.where((chat) => chat.id != chatId).toList(),
    );
  }

  void refreshChats() {
    _loadMockChats();
  }
}

/// Provider for global chats
final globalChatProvider =
    StateNotifierProvider<GlobalChatNotifier, GlobalChatState>((ref) {
  return GlobalChatNotifier();
});

/// Provider for accessing just the chat list
final globalChatsListProvider = Provider<List<GlobalChatEntity>>((ref) {
  return ref.watch(globalChatProvider).chats;
});
