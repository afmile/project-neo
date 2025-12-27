/// Project Neo - Community Presence Provider
///
/// Manages real-time presence for community members using Supabase Realtime.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// State for community presence
class CommunityPresenceState {
  final Set<String> onlineUserIds;
  final bool isConnected;

  const CommunityPresenceState({
    this.onlineUserIds = const {},
    this.isConnected = false,
  });

  int get onlineCount => onlineUserIds.length;

  bool isUserOnline(String userId) => onlineUserIds.contains(userId);

  CommunityPresenceState copyWith({
    Set<String>? onlineUserIds,
    bool? isConnected,
  }) {
    return CommunityPresenceState(
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Notifier for community presence
class CommunityPresenceNotifier extends StateNotifier<CommunityPresenceState> {
  final String communityId;
  final SupabaseClient _supabase;
  RealtimeChannel? _channel;

  CommunityPresenceNotifier({
    required this.communityId,
    SupabaseClient? supabase,
  })  : _supabase = supabase ?? Supabase.instance.client,
        super(const CommunityPresenceState()) {
    _subscribe();
  }

  void _subscribe() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _channel = _supabase.channel(
      'community_presence:$communityId',
      opts: const RealtimeChannelConfig(self: true),
    );

    _channel!
        .onPresenceSync((payload) {
          final presenceStates = _channel!.presenceState();
          final userIds = <String>{};
          
          for (final presenceState in presenceStates) {
            for (final presence in presenceState.presences) {
              final userId = presence.payload['user_id'] as String?;
              if (userId != null) {
                userIds.add(userId);
              }
            }
          }
          
          state = state.copyWith(
            onlineUserIds: userIds,
            isConnected: true,
          );
        })
        .onPresenceJoin((payload) {
          final newPresences = payload.newPresences;
          final newUserIds = <String>{};
          
          for (final presence in newPresences) {
            final userId = presence.payload['user_id'] as String?;
            if (userId != null) {
              newUserIds.add(userId);
            }
          }
          
          state = state.copyWith(
            onlineUserIds: {...state.onlineUserIds, ...newUserIds},
          );
        })
        .onPresenceLeave((payload) {
          final leftPresences = payload.leftPresences;
          final leftUserIds = <String>{};
          
          for (final presence in leftPresences) {
            final userId = presence.payload['user_id'] as String?;
            if (userId != null) {
              leftUserIds.add(userId);
            }
          }
          
          state = state.copyWith(
            onlineUserIds: state.onlineUserIds.difference(leftUserIds),
          );
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Track this user's presence
            await _channel!.track({
              'user_id': currentUserId,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

/// Provider for community presence (family by communityId)
final communityPresenceProvider = StateNotifierProvider.family<
    CommunityPresenceNotifier, CommunityPresenceState, String>(
  (ref, communityId) => CommunityPresenceNotifier(communityId: communityId),
);
