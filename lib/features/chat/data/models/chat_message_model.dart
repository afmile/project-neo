import '../../domain/entities/chat_message_entity.dart';

/// Model for chat messages with Supabase JSON parsing
class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.channelId,
    required super.userId,
    super.content,
    super.imageUrl,
    super.type,
    required super.createdAt,
    super.userName,
    super.userAvatarUrl,
  });

  /// Parse from Supabase JSON (snake_case)
  factory ChatMessageModel.fromSupabaseJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      type: json['type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  /// Convert to JSON for insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
