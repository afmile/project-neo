import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../models/community_chat_room_model.dart';

/// Repository for chat channel operations with Supabase
class ChatChannelRepository {
  final SupabaseClient _client;

  ChatChannelRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all chat channels for a community
  Future<List<CommunityChatRoomEntity>> fetchChannels(String communityId) async {
    try {
      final response = await _client
          .from('chat_channels')
          .select('*')
          .eq('community_id', communityId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      final channels = <CommunityChatRoomEntity>[];
      
      // Get unique creator IDs
      final creatorIds = (response as List)
          .map((json) => json['creator_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      // Fetch creator data in one query
      Map<String, Map<String, dynamic>> creatorData = {};
      if (creatorIds.isNotEmpty) {
        try {
          final creatorsResponse = await _client
              .from('users_global')
              .select('id, avatar_url, username')
              .inFilter('id', creatorIds);
          
          for (var creator in creatorsResponse as List) {
            creatorData[creator['id']] = creator;
          }
        } catch (e) {
          print('⚠️ Error fetching creator data: $e');
        }
      }
      
      // Parse channels with creator data
      for (var json in response as List) {
        try {
          final creatorId = json['creator_id'] as String?;
          if (creatorId != null && creatorData.containsKey(creatorId)) {
            json['creator'] = creatorData[creatorId];
          }
          
          final channel = CommunityChatRoomModel.fromSupabaseJson(json);
          channels.add(channel);
        } catch (e) {
          print('⚠️ Error parsing channel: $e');
        }
      }
      
      return channels;
    } catch (e, stackTrace) {
      print('❌ Error fetching channels: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a new chat channel
  Future<CommunityChatRoomEntity> createChannel({
    required String communityId,
    required String creatorId,
    required String title,
    String? description,
    String? iconUrl,
    String? backgroundImageUrl,
    bool voiceEnabled = false,
    bool videoEnabled = false,
    bool projectionEnabled = false,
  }) async {
    final response = await _client
        .from('chat_channels')
        .insert({
          'community_id': communityId,
          'creator_id': creatorId,
          'title': title,
          'description': description,
          'icon_url': iconUrl,
          'background_image_url': backgroundImageUrl,
          'voice_enabled': voiceEnabled,
          'video_enabled': videoEnabled,
          'projection_enabled': projectionEnabled,
        })
        .select()
        .single();

    return CommunityChatRoomModel.fromSupabaseJson(response);
  }

  /// Update a chat channel
  Future<CommunityChatRoomEntity> updateChannel({
    required String channelId,
    String? title,
    String? description,
    String? backgroundImageUrl,
    bool? isPinned,
    int? pinnedOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (backgroundImageUrl != null) updates['background_image_url'] = backgroundImageUrl;
    if (isPinned != null) updates['is_pinned'] = isPinned;
    if (pinnedOrder != null) updates['pinned_order'] = pinnedOrder;

    final response = await _client
        .from('chat_channels')
        .update(updates)
        .eq('id', channelId)
        .select()
        .single();

    return CommunityChatRoomModel.fromSupabaseJson(response);
  }

  /// Delete a chat channel
  Future<void> deleteChannel(String channelId) async {
    await _client.from('chat_channels').delete().eq('id', channelId);
  }

  /// Upload background image to Supabase Storage
  Future<String?> uploadBackgroundImage({
    required String channelId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final path = 'chat-backgrounds/$channelId/$fileName';
    
    await _client.storage
        .from('chat-backgrounds')
        .uploadBinary(path, imageBytes as dynamic);

    final publicUrl = _client.storage
        .from('chat-backgrounds')
        .getPublicUrl(path);

    return publicUrl;
  }

  /// Toggle pin status for a channel
  Future<void> togglePin(String channelId, bool isPinned, int? pinnedOrder) async {
    await _client
        .from('chat_channels')
        .update({
          'is_pinned': isPinned,
          'pinned_order': pinnedOrder,
        })
        .eq('id', channelId);
  }
}
