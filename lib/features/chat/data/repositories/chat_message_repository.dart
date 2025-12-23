import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message_entity.dart';

/// Repository for chat messages with realtime support
class ChatMessageRepository {
  final SupabaseClient _client;

  ChatMessageRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Get realtime stream of messages for a channel
  Stream<List<ChatMessageEntity>> getMessagesStream(String channelId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: true)
        .map((data) => data
            .map((json) => ChatMessageModel.fromSupabaseJson(json))
            .cast<ChatMessageEntity>()
            .toList());
  }

  /// Send a new message
  Future<ChatMessageEntity> sendMessage({
    required String channelId,
    required String userId,
    required String content,
    String? imageUrl,
    String type = 'text',
  }) async {
    final response = await _client
        .from('chat_messages')
        .insert({
          'channel_id': channelId,
          'user_id': userId,
          'content': content,
          'image_url': imageUrl,
          'type': type,
        })
        .select()
        .single();

    return ChatMessageModel.fromSupabaseJson(response);
  }

  /// Get initial messages (paginated, for loading history)
  Future<List<ChatMessageEntity>> getMessages({
    required String channelId,
    int limit = 50,
    DateTime? before,
  }) async {
    var query = _client
        .from('chat_messages')
        .select()
        .eq('channel_id', channelId);

    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ChatMessageModel.fromSupabaseJson(json as Map<String, dynamic>))
        .cast<ChatMessageEntity>()
        .toList()
        .reversed
        .toList(); // Reverse to show oldest first
  }

  /// Delete a message (only own messages)
  Future<void> deleteMessage(String messageId) async {
    await _client.from('chat_messages').delete().eq('id', messageId);
  }

  /// Upload image to Supabase Storage and return public URL
  Future<String> uploadChatImage({
    required String channelId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'chat_uploads/$channelId/${timestamp}_$fileName';

    await _client.storage.from('community-media').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    final publicUrl = _client.storage.from('community-media').getPublicUrl(path);
    return publicUrl;
  }
}

