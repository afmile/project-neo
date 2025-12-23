import 'package:equatable/equatable.dart';

/// Entity representing a chat message
class ChatMessageEntity extends Equatable {
  final String id;
  final String channelId;
  final String userId;
  final String? content;
  final String? imageUrl;
  final String type; // 'text', 'image', 'system'
  final DateTime createdAt;
  
  // User info (joined from users_global)
  final String? userName;
  final String? userAvatarUrl;

  const ChatMessageEntity({
    required this.id,
    required this.channelId,
    required this.userId,
    this.content,
    this.imageUrl,
    this.type = 'text',
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });

  @override
  List<Object?> get props => [
        id,
        channelId,
        userId,
        content,
        imageUrl,
        type,
        createdAt,
        userName,
        userAvatarUrl,
      ];
}
