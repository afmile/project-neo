/// Project Neo - Home VIVO Providers
///
/// Providers for the Home VIVO tab (community landing experience)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/post_entity.dart';
import '../../data/models/post_model.dart';
import '../../../../core/supabase/schema/schema.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CHAT CHANNELS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Represents a chat channel for Home VIVO display
class ChatChannelSimple {
  final String id;
  final String title;
  final String? description;
  final String? backgroundImageUrl;
  final int memberCount;
  final bool isPinned;

  const ChatChannelSimple({
    required this.id,
    required this.title,
    this.description,
    this.backgroundImageUrl,
    this.memberCount = 0,  // Default since column doesn't exist in DB
    this.isPinned = false,
  });

  factory ChatChannelSimple.fromJson(Map<String, dynamic> json) {
    return ChatChannelSimple(
      id: json[ChatChannelsSchema.id] as String,
      title: json[ChatChannelsSchema.title] as String,
      description: json[ChatChannelsSchema.description] as String?,
      backgroundImageUrl: json[ChatChannelsSchema.backgroundImageUrl] as String?,
      memberCount: 0,  // Column doesn't exist in DB
      isPinned: json[ChatChannelsSchema.isPinned] as bool? ?? false,
    );
  }
}

/// Provider for chat channels (Home VIVO "Ahora mismo" section)
/// 
/// Returns up to 5 channels, ordered by: is_pinned DESC, created_at DESC
/// Changed to StreamProvider.autoDispose to ensure fresh data on each view
final chatChannelsProvider = StreamProvider.autoDispose.family<List<ChatChannelSimple>, String>(
  (ref, communityId) async* {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from(ChatChannelsSchema.table)
          .select(ChatChannelsSchema.selectNow)
          .eq(ChatChannelsSchema.communityId, communityId)
          .order(ChatChannelsSchema.isPinned, ascending: false)
          .order(ChatChannelsSchema.pinnedOrder, ascending: true)
          .order(ChatChannelsSchema.createdAt, ascending: false)
          .limit(5);

      print('🔍 [HOME VIVO] chatChannelsProvider response (community: $communityId):');
      print('   Raw response: $response');
      print('   Response length: ${(response as List).length}');
      
      final channels = (response as List)
          .map((json) {
            print('   - Channel: ${json[ChatChannelsSchema.title]} (id: ${json[ChatChannelsSchema.id]}, isPinned: ${json[ChatChannelsSchema.isPinned]})');
            return ChatChannelSimple.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      print('   Total channels parsed: ${channels.length}');
      yield channels;
    } catch (e) {
      print('❌ Error loading chat channels: $e');
      yield [];
    }
  },
);

// LocalIdentity and myLocalIdentityProvider moved to local_identity_providers.dart

// ═══════════════════════════════════════════════════════════════════════════
// PINNED POST PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for single pinned community post (Home VIVO "Destacado" section)
/// 
/// Returns the most recent pinned post, or null if none exists
final pinnedPostProvider = FutureProvider.family<PostEntity?, String>(
  (ref, communityId) async {
    final supabase = Supabase.instance.client;
    final currentUserId = ref.watch(currentUserProvider)?.id;

    try {
      final response = await supabase
          .from('community_posts')
          .select('''
            *,
            author:author_id (username, avatar_global_url),
            poll_options (id, text, position, votes_count)
          ''')
          .eq('community_id', communityId)
          .eq('is_pinned', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      // Check user reaction
      bool isLiked = false;
      if (currentUserId != null) {
        final reaction = await supabase
            .from('post_reactions')
            .select('id')
            .eq('post_id', response['id'])
            .eq('user_id', currentUserId)
            .maybeSingle();
        isLiked = reaction != null;
      }

      return PostModel.fromJson(
        response,
        currentUserId: currentUserId,
        userReactions: isLiked
            ? [{'post_id': response['id'], 'user_id': currentUserId}]
            : [],
      );
    } catch (e) {
      print('❌ Error loading pinned post: $e');
      return null;
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// RECENT ACTIVITY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for recent community posts (Home VIVO "Actividad reciente" section)
/// 
/// Returns up to 5 most recent posts of any type
final recentActivityProvider = FutureProvider.family<List<PostEntity>, String>(
  (ref, communityId) async {
    final supabase = Supabase.instance.client;
    final currentUserId = ref.watch(currentUserProvider)?.id;

    try {
      final response = await supabase
          .from('community_posts')
          .select('''
            *,
            author:author_id (username, avatar_global_url),
            poll_options (id, text, position, votes_count)
          ''')
          .eq('community_id', communityId)
          .order('created_at', ascending: false)
          .limit(5);

      final posts = response as List;
      final postIds = posts.map((p) => p['id'] as String).toList();

      // Batch fetch user reactions
      List<Map<String, dynamic>> userReactions = [];
      if (currentUserId != null && postIds.isNotEmpty) {
        final reactionsResponse = await supabase
            .from('post_reactions')
            .select('post_id, user_id')
            .eq('user_id', currentUserId)
            .inFilter('post_id', postIds);
        userReactions = List<Map<String, dynamic>>.from(reactionsResponse);
      }

      return posts
          .map((json) => PostModel.fromJson(
                json as Map<String, dynamic>,
                currentUserId: currentUserId,
                userReactions: userReactions,
              ))
          .toList();
    } catch (e) {
      print('❌ Error loading recent activity: $e');
      return [];
    }
  },
);
