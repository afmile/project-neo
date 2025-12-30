/// Project Neo - User Titles Providers
///
/// Riverpod providers for managing user titles and assignments
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/member_title.dart';
import '../../domain/entities/community_title.dart';
import '../../data/repositories/titles_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for TitlesRepository
final titlesRepositoryProvider = Provider<TitlesRepository>((ref) {
  return TitlesRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════════════════════════════════════
// PARAMETERS CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Parameters for fetching user titles
class UserTitlesParams {
  final String userId;
  final String communityId;
  final int? maxTitles; // Limit display to N titles (e.g., 4)

  const UserTitlesParams({
    required this.userId,
    required this.communityId,
    this.maxTitles,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTitlesParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          communityId == other.communityId &&
          maxTitles == other.maxTitles;

  @override
  int get hashCode => userId.hashCode ^ communityId.hashCode ^ (maxTitles?.hashCode ?? 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// USER TITLES PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch user titles for a specific user in a community
/// 
/// Returns active, non-expired titles sorted by: sort_order, priority, assigned_at
/// Optionally limits to maxTitles (e.g., show only top 4)
final userTitlesProvider = FutureProvider.family<List<MemberTitle>, UserTitlesParams>(
  (ref, params) async {
    final repo = ref.read(titlesRepositoryProvider);
    
    final titles = await repo.fetchUserTitles(
      userId: params.userId,
      communityId: params.communityId,
    );

    // Limit to maxTitles if specified
    if (params.maxTitles != null && titles.length > params.maxTitles!) {
      return titles.take(params.maxTitles!).toList();
    }

    return titles;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// COMMUNITY TITLES PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch all available titles for a community (for admin UI)
final communityTitlesProvider = FutureProvider.family<List<CommunityTitle>, String>(
  (ref, communityId) async {
    final repo = ref.read(titlesRepositoryProvider);
    return repo.fetchCommunityTitles(communityId: communityId);
  },
);
