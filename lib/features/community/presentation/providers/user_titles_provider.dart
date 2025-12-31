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

// ═══════════════════════════════════════════════════════════════════════════
// USER TITLES WITH HIDDEN (FOR SETTINGS SCREEN)
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch user titles INCLUDING hidden ones (for settings screen)
/// 
/// Returns all active, non-expired titles (visible and hidden) sorted by sort_order
final userTitlesWithHiddenProvider = FutureProvider.family<List<MemberTitle>, UserTitlesParams>(
  (ref, params) async {
    final repo = ref.read(titlesRepositoryProvider);
    
    final titles = await repo.fetchUserTitlesWithHidden(
      userId: params.userId,
      communityId: params.communityId,
    );

    return titles;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// TITLE SETTINGS STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

/// State for title settings management
class TitleSettingsState {
  final List<MemberTitle> titles;
  final bool isLoading;
  final String? error;

  const TitleSettingsState({
    this.titles = const [],
    this.isLoading = false,
    this.error,
  });

  TitleSettingsState copyWith({
    List<MemberTitle>? titles,
    bool? isLoading,
    String? error,
  }) {
    return TitleSettingsState(
      titles: titles ?? this.titles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing user title settings
class UserTitlesSettingsNotifier extends StateNotifier<TitleSettingsState> {
  final TitlesRepository _repository;
  final String _userId;
  final String _communityId;

  UserTitlesSettingsNotifier({
    required TitlesRepository repository,
    required String userId,
    required String communityId,
  })  : _repository = repository,
        _userId = userId,
        _communityId = communityId,
        super(const TitleSettingsState(isLoading: true));

  /// Load titles
  Future<void> loadTitles() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final titles = await _repository.fetchUserTitlesWithHidden(
        userId: _userId,
        communityId: _communityId,
      );
      
      state = state.copyWith(titles: titles, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cargar títulos: $e',
        isLoading: false,
      );
    }
  }

  /// Reorder titles (drag and drop)
  void reorderTitles(int oldIndex, int newIndex) {
    final titles = List<MemberTitle>.from(state.titles);
    
    // Adjust newIndex if dragging down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final item = titles.removeAt(oldIndex);
    titles.insert(newIndex, item);
    
    // Update local state immediately for smooth UX
    state = state.copyWith(titles: titles);
  }

  /// Save title order to database
  Future<bool> saveTitleOrders() async {
    try {
      // Create updates list with new sort orders
      final updates = state.titles
          .asMap()
          .entries
          .map((entry) => (id: entry.value.id, order: entry.key))
          .toList();

      final success = await _repository.batchUpdateTitleOrders(updates: updates);
      
      if (!success) {
        state = state.copyWith(error: 'Error al guardar orden de títulos');
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error al guardar: $e');
      return false;
    }
  }

  /// Toggle title visibility
  Future<bool> toggleTitleVisibility(String titleId) async {
    try {
      // Find the title
      final titleIndex = state.titles.indexWhere((t) => t.id == titleId);
      if (titleIndex == -1) return false;

      final title = state.titles[titleIndex];
      final newVisibility = !title.isVisible;

      // Update in database
      final success = await _repository.updateTitleVisibility(
        assignmentId: titleId,
        isVisible: newVisibility,
      );

      if (success) {
        // Update local state
        final updatedTitles = List<MemberTitle>.from(state.titles);
        updatedTitles[titleIndex] = MemberTitle(
          id: title.id,
          communityId: title.communityId,
          memberUserId: title.memberUserId,
          title: title.title,
          assignedBy: title.assignedBy,
          assignedAt: title.assignedAt,
          expiresAt: title.expiresAt,
          isActive: title.isActive,
          sortOrder: title.sortOrder,
          isVisible: newVisibility,
        );
        
        state = state.copyWith(titles: updatedTitles);
      } else {
        state = state.copyWith(error: 'Error al actualizar visibilidad');
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
      return false;
    }
  }

  /// Hide title (with confirmation)
  Future<bool> hideTitle(String titleId) async {
    return toggleTitleVisibility(titleId);
  }

  /// Show title
  Future<bool> showTitle(String titleId) async {
    return toggleTitleVisibility(titleId);
  }
}

/// Provider for title settings notifier
final userTitlesSettingsNotifierProvider = StateNotifierProvider.family<
    UserTitlesSettingsNotifier,
    TitleSettingsState,
    ({String userId, String communityId})>(
  (ref, params) {
    final repository = ref.read(titlesRepositoryProvider);
    final notifier = UserTitlesSettingsNotifier(
      repository: repository,
      userId: params.userId,
      communityId: params.communityId,
    );
    
    // Load titles on creation
    notifier.loadTitles();
    
    return notifier;
  },
);
