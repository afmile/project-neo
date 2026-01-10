/// Project Neo - Community Members Provider
///
/// Fetches real users from users_global table.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A member of a community with their profile info
class CommunityMember {
  final String id;
  final String username;      // Global username (from users_global)
  final String? nickname;     // Local community nickname (from community_members)
  final String? avatarUrl;    // Can be local or global
  final String role;
  final DateTime joinedAt;
  
  // Role badges
  final bool isFounder;       // owner role
  final bool isLeader;        // is_leader from DB
  final bool isModerator;     // is_moderator from DB

  const CommunityMember({
    required this.id,
    required this.username,
    this.nickname,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.isFounder = false,
    this.isLeader = false,
    this.isModerator = false,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    // Parse nested user object from JOIN query
    final userObj = json['user'] as Map<String, dynamic>?;
    final role = json['role'] as String? ?? 'member';
    
    return CommunityMember(
      id: json['user_id'] as String,
      username: userObj?['username'] as String? ?? 'Usuario',
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? 
                userObj?['avatar_global_url'] as String?,
      role: role,
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
      isFounder: role == 'owner',
      isLeader: json['is_leader'] as bool? ?? false,
      isModerator: json['is_moderator'] as bool? ?? false,
    );
  }

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

/// Provider to fetch community members
final communityMembersProvider = FutureProvider.family<List<CommunityMember>, String>(
  (ref, communityId) async {
    final supabase = Supabase.instance.client;

    try {
      print('🔍 Fetching members for community: $communityId');
      
      // Fetch members with JOIN to users_global for fallback data
      // Using explicit FK hint to avoid ambiguous join error
      final response = await supabase
          .from('community_members')
          .select('''
            user_id, role, joined_at, nickname, avatar_url, is_leader, is_moderator, is_active,
            users_global!community_members_user_id_fkey(username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('is_active', true) // Only active members
          .order('is_leader', ascending: false)
          .order('is_moderator', ascending: false)
          .order('joined_at', ascending: false);

      print('📦 Fetched ${(response as List).length} members');

      final members = (response as List).map((json) {
        // Extract user data from the join
        final userData = json['users_global'] as Map<String, dynamic>?;
        final globalUsername = userData?['username'] as String? ?? 'Usuario';
        final globalAvatar = userData?['avatar_global_url'] as String?;

        // Resolve Local Identity with fallback to Global
        final String displayName = json['nickname'] as String? ?? globalUsername;
        final String? displayAvatar = json['avatar_url'] as String? ?? globalAvatar;
        final String role = json['role'] as String? ?? 'member';

        // Debug first member
        if ((response as List).indexOf(json) == 0) {
          print('🔍 Sample Member: $displayName (role: $role)');
        }

        return CommunityMember(
          id: json['user_id'] as String,
          username: displayName, // ✅ Display local nickname or global username
          nickname: json['nickname'] as String?, // Keep original nickname
          avatarUrl: displayAvatar, // ✅ Display local avatar or global avatar
          role: role,
          joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
          isFounder: role == 'owner',
          isLeader: json['is_leader'] as bool? ?? false,
          isModerator: json['is_moderator'] as bool? ?? false,
        );
      }).toList();

      print('✅ Processed ${members.length} members with local identities');
      return members;
    } catch (e, stack) {
      print('🔴 Error fetching members: $e');
      print('📍 Stack trace: $stack');
      // Return empty list on error
      return [];
    }
  },
);
