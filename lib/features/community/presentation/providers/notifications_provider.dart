/// Project Neo - Notifications Providers
///
/// Riverpod providers for community notifications
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_notification.dart';
import '../../data/repositories/notifications_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS LIST PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Fetch notifications for a community (auto-refreshable)
final communityNotificationsProvider = FutureProvider.family<List<CommunityNotification>, String>(
  (ref, communityId) async {
    final repo = ref.read(notificationsRepositoryProvider);
    return repo.fetchNotifications(communityId: communityId);
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// UNREAD COUNT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Count unread notifications for a community
final unreadNotificationsCountProvider = FutureProvider.family<int, String>(
  (ref, communityId) async {
    final repo = ref.read(notificationsRepositoryProvider);
    return repo.countUnread(communityId);
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION ACTIONS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationsRepository _repo;
  final String communityId;
  final Ref _ref;

  NotificationActionsNotifier(this._repo, this.communityId, this._ref)
      : super(const AsyncValue.data(null));

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    final success = await _repo.markAsRead(notificationId);
    state = const AsyncValue.data(null);
    
    if (success) {
      _invalidateProviders();
    }
    return success;
  }

  /// Mark all as read
  Future<int> markAllAsRead() async {
    state = const AsyncValue.loading();
    final count = await _repo.markAllAsRead(communityId);
    state = const AsyncValue.data(null);
    
    _invalidateProviders();
    return count;
  }

  /// Resolve an actionable notification (accept/reject)
  Future<bool> resolveAction({
    required String notificationId,
    required bool accepted,
    required String entityType,
    required String entityId,
  }) async {
    state = const AsyncValue.loading();
    
    final success = await _repo.resolveAction(
      notificationId: notificationId,
      accepted: accepted,
      entityType: entityType,
      entityId: entityId,
    );
    
    state = const AsyncValue.data(null);
    
    if (success) {
      _invalidateProviders();
    }
    return success;
  }

  void _invalidateProviders() {
    _ref.invalidate(communityNotificationsProvider(communityId));
    _ref.invalidate(unreadNotificationsCountProvider(communityId));
  }
}

/// Provider for notification actions
final notificationActionsProvider = StateNotifierProvider.family<
    NotificationActionsNotifier, AsyncValue<void>, String>(
  (ref, communityId) {
    final repo = ref.read(notificationsRepositoryProvider);
    return NotificationActionsNotifier(repo, communityId, ref);
  },
);
