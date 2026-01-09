/// Project Neo - Local Identity Providers
///
/// Providers for managing user's local identity within communities
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LOCAL IDENTITY
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
    if (currentUser == null) {
      print('⚠️ [LOCAL IDENTITY] No current user');
      return null;
    }

    print('🔍 [LOCAL IDENTITY] Fetching for communityId: $communityId, userId: ${currentUser.id}');

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('community_members')
          .select('''
            user_id, community_id, nickname, avatar_url, bio, role,
            users_global!community_members_user_id_fkey(username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('user_id', currentUser.id)
          .eq('is_active', true)
          .maybeSingle();

      print('📦 [LOCAL IDENTITY] Response: $response');

      if (response == null) {
        print('⚠️ [LOCAL IDENTITY] No member record found');
        return null;
      }

      final userData = response['users_global'] as Map<String, dynamic>?;
      final globalUsername = userData?['username'] as String? ?? 'Usuario';
      final globalAvatar = userData?['avatar_global_url'] as String?;

      final localIdentity = LocalIdentity(
        userId: response['user_id'] as String,
        communityId: response['community_id'] as String,
        displayName: response['nickname'] as String? ?? globalUsername,
        avatarUrl: response['avatar_url'] as String? ?? globalAvatar,
        bio: response['bio'] as String?,
        role: response['role'] as String? ?? 'member',
      );

      print('✅ [LOCAL IDENTITY] Loaded:');
      print('   - displayName: ${localIdentity.displayName}');
      print('   - avatarUrl: ${localIdentity.avatarUrl}');
      print('   - role: ${localIdentity.role}');

      return localIdentity;
    } catch (e) {
      print('❌ [LOCAL IDENTITY] Error loading: $e');
      return null;
    }
  },
);
