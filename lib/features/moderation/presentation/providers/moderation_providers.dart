/// Project Neo - Moderation Providers
///
/// Riverpod providers for moderation system
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/moderation_repository_impl.dart';
import '../domain/repositories/moderation_repository.dart';
import '../domain/entities/strike_entity.dart';

// Repository provider
final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepositoryImpl(Supabase.instance.client);
});

// User strikes provider
final userStrikesProvider = FutureProvider.autoDispose.family<List<Strike>, ({String userId, String communityId})>(
  (ref, params) async {
    final repository = ref.watch(moderationRepositoryProvider);
    return repository.getUserStrikes(params.userId, params.communityId);
  },
);

// Active strikes count provider
final activeStrikesCountProvider = FutureProvider.autoDispose.family<int, ({String userId, String communityId})>(
  (ref, params) async {
    final repository = ref.watch(moderationRepositoryProvider);
    return repository.countActiveStrikes(params.userId, params.communityId);
  },
);

// Strikes needing review provider (for leaders)
final strikesNeedingReviewProvider = FutureProvider.autoDispose.family<Map<String, List<Strike>>, String>(
  (ref, communityId) async {
    final repository = ref.watch(moderationRepositoryProvider);
    return repository.getStrikesNeedingReview(communityId);
  },
);

// Strike assignment state provider
final strikeAssignmentProvider = StateNotifierProvider.autoDispose<StrikeAssignmentNotifier, AsyncValue<void>>(
  (ref) => StrikeAssignmentNotifier(ref.watch(moderationRepositoryProvider)),
);

class StrikeAssignmentNotifier extends StateNotifier<AsyncValue<void>> {
  final ModerationRepository _repository;

  StrikeAssignmentNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> assignStrike({
    required String communityId,
    required String userId,
    required String reason,
    String? contentType,
    String? contentId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.assignStrike(
        communityId: communityId,
        userId: userId,
        reason: reason,
        contentType: contentType,
        contentId: contentId,
      );
    });
  }

  Future<void> revokeStrike({
    required String strikeId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.revokeStrike(
        strikeId: strikeId,
        reason: reason,
      );
    });
  }
}
