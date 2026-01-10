/// Project Neo - Notifications Repository
///
/// Handles community notification operations
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_notification.dart';
import './friendship_repository.dart';

class NotificationsRepository {
  final SupabaseClient _supabase;
  final FriendshipRepository _friendshipRepository;

  NotificationsRepository(this._supabase, this._friendshipRepository);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch notifications for current user in a community (using local nicknames)
  Future<List<CommunityNotification>> fetchNotifications({
    required String communityId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('community_notifications')
          .select('*')
          .eq('community_id', communityId)
          .eq('recipient_id', _currentUserId!)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final notifications = response as List<dynamic>;
      if (notifications.isEmpty) return [];

      // Collect all actor IDs (exclude nulls)
      final actorIds = notifications
          .where((n) => n['actor_id'] != null)
          .map((n) => n['actor_id'] as String)
          .toSet();

      // Fetch local profiles from community_members
      Map<String, Map<String, dynamic>> profileMap = {};
      if (actorIds.isNotEmpty) {
        final localProfiles = await _supabase
            .from('community_members')
            .select('user_id, nickname, avatar_url')
            .eq('community_id', communityId)
            .inFilter('user_id', actorIds.toList());

        for (final profile in localProfiles as List) {
          profileMap[profile['user_id'] as String] = profile;
        }
      }

      return notifications.map((json) {
        final actorId = json['actor_id'] as String?;
        final localProfile = actorId != null ? profileMap[actorId] : null;
        return _fromJson(
          json,
          actorData: localProfile != null
              ? {
                  'username': localProfile['nickname'],
                  'avatar_global_url': localProfile['avatar_url'],
                }
              : null,
        );
      }).toList();
    } catch (e) {
      print('❌ ERROR fetchNotifications: $e');
      return [];
    }
  }

  /// Count unread notifications
  Future<int> countUnread(String communityId) async {
    try {
      final response = await _supabase
          .rpc('count_unread_notifications', params: {
            'p_community_id': communityId,
            'p_user_id': _currentUserId,
          });
      return response as int? ?? 0;
    } catch (e) {
      print('❌ ERROR countUnread: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mark a single notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('community_notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId)
          .eq('recipient_id', _currentUserId!);
      return true;
    } catch (e) {
      print('❌ ERROR markAsRead: $e');
      return false;
    }
  }

  /// Mark all notifications as read in a community
  Future<int> markAllAsRead(String communityId) async {
    try {
      final response = await _supabase
          .rpc('mark_all_notifications_read', params: {
            'p_community_id': communityId,
          });
      return response as int? ?? 0;
    } catch (e) {
      print('❌ ERROR markAllAsRead: $e');
      return 0;
    }
  }

  /// Resolve an actionable notification (accept/reject)
  /// This updates both the notification AND delegates to appropriate repository
  Future<bool> resolveAction({
    required String notificationId,
    required bool accepted,
    required String entityType,
    required String entityId,
  }) async {
    try {
      final status = accepted ? 'accepted' : 'rejected';

      // 1. Update the related entity first (delegate to appropriate repository)
      bool entityUpdateSuccess = false;
      
      if (entityType == 'friendship_request') {
        // Delegate to FriendshipRepository - single source of truth
        if (accepted) {
          entityUpdateSuccess = await _friendshipRepository.acceptRequest(entityId);
        } else {
          entityUpdateSuccess = await _friendshipRepository.rejectRequest(entityId);
        }
        
        // If friendship action failed, don't update notification
        if (!entityUpdateSuccess) {
          print('❌ Failed to $status friendship request $entityId');
          return false;
        }
      }

      // 2. Update the notification only if entity update succeeded
      await _supabase
          .from('community_notifications')
          .update({
            'action_status': status,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_id', _currentUserId!);

      return true;
    } catch (e) {
      print('❌ ERROR resolveAction: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  CommunityNotification _fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? actorData,
  }) {
    return CommunityNotification(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      recipientId: json['recipient_id'] as String,
      actorId: json['actor_id'] as String?,
      type: _parseType(json['type'] as String),
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      actionStatus: _parseActionStatus(json['action_status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      actorName: actorData?['username'] as String?,
      actorAvatar: actorData?['avatar_global_url'] as String?,
    );
  }

  NotificationType _parseType(String type) {
    switch (type) {
      case 'friendship_request':
        return NotificationType.friendshipRequest;
      case 'follow':
        return NotificationType.follow;
      case 'wall_post_like':
        return NotificationType.wallPostLike;
      case 'comment_like':
        return NotificationType.commentLike;
      case 'comment':
        return NotificationType.comment;
      case 'mention':
        return NotificationType.mention;
      case 'mod_action':
        return NotificationType.modAction;
      case 'announcement':
        return NotificationType.announcement;
      case 'role_invitation': // ✅ New case
        return NotificationType.roleInvitation;
      default:
        return NotificationType.system;
    }
  }

  NotificationActionStatus? _parseActionStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'pending':
        return NotificationActionStatus.pending;
      case 'accepted':
        return NotificationActionStatus.accepted;
      case 'rejected':
        return NotificationActionStatus.rejected;
      default:
        return null;
    }
  }
}
