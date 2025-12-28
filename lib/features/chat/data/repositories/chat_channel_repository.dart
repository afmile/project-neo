import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../models/community_chat_room_model.dart';
import '../../../../core/supabase/schema/schema.dart';

/// Repository for chat channel operations with Supabase
class ChatChannelRepository {
  final SupabaseClient _client;

  ChatChannelRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all chat channels for a community
  Future<List<CommunityChatRoomEntity>> fetchChannels(String communityId) async {
    try {
      final response = await _client
          .from(ChatChannelsSchema.table)
          .select(ChatChannelsSchema.selectFull)
          .eq(ChatChannelsSchema.communityId, communityId)
          .order(ChatChannelsSchema.isPinned, ascending: false)
          .order(ChatChannelsSchema.createdAt, ascending: false);

      final channels = <CommunityChatRoomEntity>[];
      
      // Get unique owner IDs
      final ownerIds = (response as List)
          .map((json) => json[ChatChannelsSchema.ownerId] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
      
      // Fetch owner data in one query
      Map<String, Map<String, dynamic>> ownerData = {};
      if (ownerIds.isNotEmpty) {
        try {
          final ownersResponse = await _client
              .from(UsersGlobalSchema.table)
              .select(UsersGlobalSchema.selectBasic)
              .inFilter(UsersGlobalSchema.id, ownerIds);
          
          for (var owner in ownersResponse as List) {
            ownerData[owner[UsersGlobalSchema.id]] = owner;
          }
        } catch (e) {
          print('⚠️ Error fetching owner data: $e');
        }
      }
      
      // Parse channels with owner data
      for (var json in response as List) {
        try {
          final ownerId = json[ChatChannelsSchema.ownerId] as String?;
          if (ownerId != null && ownerData.containsKey(ownerId)) {
            json['owner'] = ownerData[ownerId];
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
    required String ownerId,  // Changed from creatorId to match schema
    required String title,
    String? description,
    String? iconUrl,
    String? backgroundImageUrl,
    bool voiceEnabled = false,
    bool videoEnabled = false,
    bool projectionEnabled = false,
  }) async {
    final response = await _client
        .from(ChatChannelsSchema.table)
        .insert({
          ChatChannelsSchema.communityId: communityId,
          ChatChannelsSchema.ownerId: ownerId,
          ChatChannelsSchema.title: title,
          ChatChannelsSchema.description: description,
          ChatChannelsSchema.iconUrl: iconUrl,
          ChatChannelsSchema.backgroundImageUrl: backgroundImageUrl,
          ChatChannelsSchema.voiceEnabled: voiceEnabled,
          ChatChannelsSchema.videoEnabled: videoEnabled,
          ChatChannelsSchema.projectionEnabled: projectionEnabled,
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
