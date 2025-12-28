/// Project Neo - Home VIVO Providers
///
/// Providers for the Home VIVO tab (community landing experience)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/post_entity.dart';
import '../../data/models/post_model.dart';

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
    required this.memberCount,
    required this.isPinned,
  });

  factory ChatChannelSimple.fromJson(Map<String, dynamic> json) {
    return ChatChannelSimple(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      backgroundImageUrl: json['background_image_url'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }
}

/// Provider for chat channels (Home VIVO "Ahora mismo" section)
/// 
/// Returns up to 5 channels, ordered by: is_pinned DESC, created_at DESC
final chatChannelsProvider = FutureProvider.family<List<ChatChannelSimple>, String>(
  (ref, communityId) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('chat_channels')
          .select('id, title, description, background_image_url, member_count, is_pinned')
          .eq('community_id', communityId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(5);

      return (response as List)
          .map((json) => ChatChannelSimple.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading chat channels: $e');
      return [];
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// LOCAL IDENTITY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Represents user's local identity in a community
class LocalIdentity {
  final String userId;
  final String communityId;
  final String displayName; // nickname or global username
  final String? avatarUrl; // local or global avatar
  final String? bio;
  final String role;

  const LocalIdentity({
    required this.userId,
    required this.communityId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.role,
  });

  String get roleDisplayName {
    switch (role) {
      case 'owner':
        return 'Dueño';
      case 'agent':
        return 'Agente';
      case 'leader':
        return 'Líder';
      default:
        return 'Miembro';
    }
  }
}

/// Provider for current user's local identity in community
/// 
/// Fetches from community_members with fallback to global profile
final myLocalIdentityProvider = FutureProvider.family<LocalIdentity?, String>(
  (ref, communityId) async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return null;

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('community_members')
          .select('''
            user_id, community_id, nickname, avatar_url, bio, role,
            user:users_global(username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('user_id', currentUser.id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final userData = response['user'] as Map<String, dynamic>?;
      final globalUsername = userData?['username'] as String? ?? 'Usuario';
      final globalAvatar = userData?['avatar_global_url'] as String?;

      return LocalIdentity(
        userId: response['user_id'] as String,
        communityId: response['community_id'] as String,
        displayName: response['nickname'] as String? ?? globalUsername,
        avatarUrl: response['avatar_url'] as String? ?? globalAvatar,
        bio: response['bio'] as String?,
        role: response['role'] as String? ?? 'member',
      );
    } catch (e) {
      print('❌ Error loading local identity: $e');
      return null;
    }
  },
);

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
