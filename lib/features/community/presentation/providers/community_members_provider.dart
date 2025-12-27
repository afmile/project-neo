/// Project Neo - Community Members Provider
///
/// Fetches real community members from the memberships table.
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
    final userGlobal = json['users_global'] as Map<String, dynamic>?;
    return CommunityMember(
      id: json['user_id'] as String,
      username: userGlobal?['username'] as String? ?? 'Usuario',
      avatarUrl: userGlobal?['avatar_global_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
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

    final response = await supabase
        .from('memberships')
        .select('''
          user_id,
          role,
          joined_at,
          users_global!inner(
            username,
            avatar_global_url
          )
        ''')
        .eq('community_id', communityId)
        .order('joined_at', ascending: true);

    final members = (response as List)
        .map((json) => CommunityMember.fromJson(json as Map<String, dynamic>))
        .toList();

    // Sort: owners first, then agents, leaders, members
    members.sort((a, b) {
      const order = ['owner', 'agent', 'leader', 'member'];
      return order.indexOf(a.role).compareTo(order.indexOf(b.role));
    });

    return members;
  },
);
