/// Project Neo - Title Request Providers
///
/// State management for title request system
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/titles_repository.dart';
import '../../domain/entities/title_request.dart';
import '../providers/community_providers.dart';
import '../providers/user_titles_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS FOR FETCHING REQUESTS
// ═══════════════════════════════════════════════════════════════════════════

/// Fetch user's title requests in a community
final userTitleRequestsProvider = FutureProvider.family<List<TitleRequest>, ({String userId, String communityId})>(
  (ref, params) async {
    final repository = ref.watch(titlesRepositoryProvider);
    return repository.fetchUserTitleRequests(
      userId: params.userId,
      communityId: params.communityId,
    );
  },
);

/// Fetch pending title requests for a community (leaders only)
final pendingTitleRequestsProvider = FutureProvider.family<List<TitleRequest>, String>(
  (ref, communityId) async {
    final repository = ref.watch(titlesRepositoryProvider);
    return repository.fetchPendingTitleRequests(communityId: communityId);
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// TITLE REQUEST ACTIONS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for title request actions (approve/reject/delete)
final titleRequestActionsProvider = Provider<TitleRequestActions>((ref) {
  final repository = ref.watch(titlesRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  return TitleRequestActions(
    repository: repository,
    userId: user?.id ?? '',
  );
});

class TitleRequestActions {
  final TitlesRepository repository;
  final String userId;

  TitleRequestActions({
    required this.repository,
    required this.userId,
  });

  /// Approve a title request
  Future<bool> approve(String requestId) async {
    return repository.approveTitleRequest(
      requestId: requestId,
      leaderId: userId,
    );
  }

  /// Reject a title request
  Future<bool> reject(String requestId) async {
    return repository.rejectTitleRequest(
      requestId: requestId,
      leaderId: userId,
    );
  }

  /// Delete a title request
  Future<bool> delete(String requestId) async {
    return repository.deleteTitleRequest(requestId: requestId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TITLE REQUEST CREATION STATE
// ═══════════════════════════════════════════════════════════════════════════

/// State for title request creation
class TitleRequestCreationState {
  final String titleText;
  final String textColor;
  final String backgroundColor;
  final bool isLoading;
  final String? error;

  const TitleRequestCreationState({
    this.titleText = '',
    this.textColor = 'FFFFFF',
    this.backgroundColor = '1337EC',
    this.isLoading = false,
    this.error,
  });

  TitleRequestCreationState copyWith({
    String? titleText,
    String? textColor,
    String? backgroundColor,
    bool? isLoading,
    String? error,
  }) {
    return TitleRequestCreationState(
      titleText: titleText ?? this.titleText,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isValid => titleText.trim().isNotEmpty && titleText.length <= 30;
}

/// Notifier for creating title requests
class TitleRequestCreationNotifier extends StateNotifier<TitleRequestCreationState> {
  final TitlesRepository _repository;
  final String _communityId;
  final String _userId;

  TitleRequestCreationNotifier({
    required TitlesRepository repository,
    required String communityId,
    required String userId,
  })  : _repository = repository,
        _communityId = communityId,
        _userId = userId,
        super(const TitleRequestCreationState());

  void updateTitleText(String text) {
    state = state.copyWith(titleText: text, error: null);
  }

  void updateTextColor(String color) {
    state = state.copyWith(textColor: color, error: null);
  }

  void updateBackgroundColor(String color) {
    state = state.copyWith(backgroundColor: color, error: null);
  }

  Future<bool> submitRequest() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'El título debe tener entre 1 y 30 caracteres');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = await _repository.createTitleRequest(
        communityId: _communityId,
        userId: _userId,
        titleText: state.titleText.trim(),
        textColor: state.textColor,
        backgroundColor: state.backgroundColor,
      );

      if (request != null) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al crear la solicitud',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
      return false;
    }
  }

  void reset() {
    state = const TitleRequestCreationState();
  }
}

/// Provider for title request creation
final titleRequestCreationNotifierProvider = StateNotifierProvider.family<
    TitleRequestCreationNotifier,
    TitleRequestCreationState,
    ({String communityId, String userId})>(
  (ref, params) {
    final repository = ref.watch(titlesRepositoryProvider);
    return TitleRequestCreationNotifier(
      repository: repository,
      communityId: params.communityId,
      userId: params.userId,
    );
  },
);
