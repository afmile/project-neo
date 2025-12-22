import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_entity.dart';
import '../../data/models/chat_model.dart';

/// State class for chat management
class ChatState {
  final List<ChatEntity> chats;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatEntity>? chats,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing chat state
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState()) {
    _loadMockChats();
  }

  void _loadMockChats() {
    state = state.copyWith(isLoading: true);

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final mockChats = _generateMockChats();
      state = state.copyWith(
        chats: mockChats,
        isLoading: false,
      );
    });
  }

  List<ChatEntity> _generateMockChats() {
    final now = DateTime.now();

    return [
      // Private 1v1 Chat
      ChatModel(
        id: 'chat_1',
        type: ChatType.privateOneOnOne,
        title: 'María García',
        participants: const [
          ChatParticipantModel(
            id: 'user_1',
            username: 'María García',
            avatarUrl: null,
            isOnline: true,
          ),
        ],
        lastMessage: ChatMessageModel(
          id: 'msg_1',
          senderId: 'user_1',
          senderUsername: 'María García',
          content: '¿Viste el último episodio? 🔥',
          timestamp: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        avatarUrl: null,
        isGroup: false,
      ),

      // Private Group Chat
      ChatModel(
        id: 'chat_2',
        type: ChatType.privateGroup,
        title: 'Amigos del Anime',
        participants: const [
          ChatParticipantModel(
            id: 'user_2',
            username: 'Carlos',
            avatarUrl: null,
            isOnline: true,
          ),
          ChatParticipantModel(
            id: 'user_3',
            username: 'Ana',
            avatarUrl: null,
            isOnline: false,
          ),
          ChatParticipantModel(
            id: 'user_4',
            username: 'Luis',
            avatarUrl: null,
            isOnline: true,
          ),
        ],
        lastMessage: ChatMessageModel(
          id: 'msg_2',
          senderId: 'user_2',
          senderUsername: 'Carlos',
          content: 'Nos vemos el sábado para el maratón!',
          timestamp: now.subtract(const Duration(hours: 2)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        unreadCount: 0,
        avatarUrl: null,
        isGroup: true,
      ),

      // Public Room Joined
      ChatModel(
        id: 'chat_3',
        type: ChatType.publicRoomJoined,
        title: 'Sala General',
        participants: const [
          ChatParticipantModel(
            id: 'user_5',
            username: 'Moderador',
            avatarUrl: null,
            isOnline: true,
          ),
        ],
        lastMessage: ChatMessageModel(
          id: 'msg_3',
          senderId: 'user_5',
          senderUsername: 'Moderador',
          content: 'Bienvenidos a la comunidad de Anime Fans!',
          timestamp: now.subtract(const Duration(hours: 5)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 5)),
        unreadCount: 0,
        avatarUrl: null,
        isGroup: true,
        communityId: 'community_1',
        communityName: 'Anime Fans',
      ),

      // Another Private 1v1
      ChatModel(
        id: 'chat_4',
        type: ChatType.privateOneOnOne,
        title: 'JuanPerez',
        participants: const [
          ChatParticipantModel(
            id: 'user_6',
            username: 'JuanPerez',
            avatarUrl: null,
            isOnline: false,
          ),
        ],
        lastMessage: ChatMessageModel(
          id: 'msg_4',
          senderId: 'user_6',
          senderUsername: 'JuanPerez',
          content: 'Sale una partida de LoL?',
          timestamp: now.subtract(const Duration(days: 1)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
        avatarUrl: null,
        isGroup: false,
      ),

      // Public Room with unread
      ChatModel(
        id: 'chat_5',
        type: ChatType.publicRoomJoined,
        title: 'Dudas y Soporte',
        participants: const [
          ChatParticipantModel(
            id: 'user_7',
            username: 'Admin',
            avatarUrl: null,
            isOnline: true,
          ),
        ],
        lastMessage: ChatMessageModel(
          id: 'msg_5',
          senderId: 'user_7',
          senderUsername: 'Admin',
          content: 'Gracias por el reporte, lo revisaremos.',
          timestamp: now.subtract(const Duration(hours: 12)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(hours: 12)),
        unreadCount: 5,
        avatarUrl: null,
        isGroup: true,
        communityId: 'community_2',
        communityName: 'Neo Official',
      ),

      // Private Group with unread
      ChatModel(
        id: 'chat_6',
        type: ChatType.privateGroup,
        title: 'Equipo de Proyecto',
        participants: const [
          ChatParticipantModel(
            id: 'user_8',
            username: 'Sofia',
            avatarUrl: null,
            isOnline: true,
          ),
          ChatParticipantModel(
            id: 'user_9',
            username: 'Diego',
            avatarUrl: null,
            isOnline: true,
          ),
        ],
        lastMessage: ChatMessageModel(
          id: 'msg_6',
          senderId: 'user_8',
          senderUsername: 'Sofia',
          content: 'Subí los archivos al repositorio',
          timestamp: now.subtract(const Duration(minutes: 30)),
          isRead: false,
        ),
        lastMessageTime: now.subtract(const Duration(minutes: 30)),
        unreadCount: 1,
        avatarUrl: null,
        isGroup: true,
      ),

      // Old conversation
      ChatModel(
        id: 'chat_7',
        type: ChatType.privateOneOnOne,
        title: 'Elena Ruiz',
        participants: const [
          ChatParticipantModel(
            id: 'user_10',
            username: 'Elena Ruiz',
            avatarUrl: null,
            isOnline: false,
          ),
        ],
        lastMessage: ChatMessageModel(
          id: 'msg_7',
          senderId: 'user_10',
          senderUsername: 'Elena Ruiz',
          content: 'Perfecto, hablamos luego!',
          timestamp: now.subtract(const Duration(days: 3)),
          isRead: true,
        ),
        lastMessageTime: now.subtract(const Duration(days: 3)),
        unreadCount: 0,
        avatarUrl: null,
        isGroup: false,
      ),
    ];
  }

  void refreshChats() {
    _loadMockChats();
  }
}

/// Provider for user's chats
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

/// Provider for accessing just the chat list
final userChatsProvider = Provider<List<ChatEntity>>((ref) {
  return ref.watch(chatProvider).chats;
});
