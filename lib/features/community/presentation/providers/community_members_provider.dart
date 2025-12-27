/// Project Neo - Community Members Provider
///
/// Fetches real users from users_global table.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A member of a community with their profile info
class CommunityMember {
  final String id;
  final String username;
  final String? avatarUrl;
  final String role; // 'owner', 'agent', 'leader', 'member'
  final DateTime joinedAt;

  const CommunityMember({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'Usuario',
      avatarUrl: json['avatar_global_url'] as String?,
      role: 'member', // Default as per requirements
      joinedAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
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
      // Fetch members with JOIN to users_global for fallback data
      final response = await supabase
          .from('community_members')
          .select('''
            user_id, role, joined_at, nickname, avatar_url,
            user:users_global(username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('is_active', true) // Only active members
          .order('joined_at', ascending: false);

      final members = (response as List).map((json) {
        // Fallback Logic:
        // 1. Local Community Nickname/Avatar
        // 2. Global User Username/Avatar
        // 3. Defaults
        
        final userData = json['user'] as Map<String, dynamic>?;
        final globalUsername = userData?['username'] as String? ?? 'Usuario';
        final globalAvatar = userData?['avatar_global_url'] as String?;

        return CommunityMember(
          id: json['user_id'] as String,
          username: json['nickname'] as String? ?? globalUsername, 
          avatarUrl: json['avatar_url'] as String? ?? globalAvatar,
          role: json['role'] as String? ?? 'member',
          joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();

      return members;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  },
);
