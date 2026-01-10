/// Project Neo - Community Moderation Repository
///
/// Repository for moderation operations: reports, activity logs, content deletion
library;

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';

// =============================================================================
// ENTITIES
// =============================================================================

class CommunityReport {
  final String id;
  final DateTime createdAt;
  final String communityId;
  final String? reporterId; // NULL = AI/System report
  final String accusedId;
  final String? postId;
  final String? commentId;
  final String reason;
  final String? description;
  final String priority; // 'normal', 'high', 'critical'
  final String status; // 'pending', 'resolved', 'dismissed'
  final String? resolutionNote;
  
  // Joined profile data
  final String? reporterUsername;
  final String? reporterAvatar;
  final String accusedUsername;
  final String? accusedAvatar;

  const CommunityReport({
    required this.id,
    required this.createdAt,
    required this.communityId,
    this.reporterId,
    required this.accusedId,
    this.postId,
    this.commentId,
    required this.reason,
    this.description,
    required this.priority,
    required this.status,
    this.resolutionNote,
    this.reporterUsername,
    this.reporterAvatar,
    required this.accusedUsername,
    this.accusedAvatar,
  });

  bool get isAIReport => reporterId == null;
  bool get isCritical => priority == 'critical';
  bool get isPending => status == 'pending';

  factory CommunityReport.fromJson(Map<String, dynamic> json) {
    return CommunityReport(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      communityId: json['community_id'] as String,
      reporterId: json['reporter_id'] as String?,
      accusedId: json['accused_id'] as String,
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String,
      status: json['status'] as String,
      resolutionNote: json['resolution_note'] as String?,
      reporterUsername: json['reporter_username'] as String?,
      reporterAvatar: json['reporter_avatar'] as String?,
      accusedUsername: json['accused_username'] as String? ?? 'Unknown',
      accusedAvatar: json['accused_avatar'] as String?,
    );
  }
}

class ActivityLog {
  final String id;
  final DateTime createdAt;
  final String communityId;
  final String? actorId;
  final String? targetUserId;
  final String actionType; // 'CONTENT_REMOVED', 'GLOBAL_BAN', etc.
  final String entityType; // 'post', 'comment', 'user'
  final String? entityId;
  final Map<String, dynamic>? metadata; // JSONB data
  
  // Joined profile data
  final String? actorUsername;
  final String? actorAvatar;
  final String? targetUsername;
  final String? targetAvatar;

  const ActivityLog({
    required this.id,
    required this.createdAt,
    required this.communityId,
    this.actorId,
    this.targetUserId,
    required this.actionType,
    required this.entityType,
    this.entityId,
    this.metadata,
    this.actorUsername,
    this.actorAvatar,
    this.targetUsername,
    this.targetAvatar,
  });

  bool get isContentRemoval => actionType == 'CONTENT_REMOVED';
  
  // Extract deleted content from metadata
  String? get deletedContent => metadata?['body'] as String?;
  String? get deletedImageUrl => metadata?['image_url'] as String?;
  int? get deletedLikeCount => metadata?['like_count'] as int?;
  int? get deletedCommentCount => metadata?['comment_count'] as int?;
  String? get originalCreatedAt => metadata?['created_at'] as String?;

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      communityId: json['community_id'] as String,
      actorId: json['actor_id'] as String?,
      targetUserId: json['target_user_id'] as String?,
      actionType: json['action_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      actorUsername: json['actor_username'] as String?,
      actorAvatar: json['actor_avatar'] as String?,
      targetUsername: json['target_username'] as String?,
      targetAvatar: json['target_avatar'] as String?,
    );
  }
}

// =============================================================================
// REPOSITORY INTERFACE
// =============================================================================

abstract class CommunityModerationRepository {
  /// Fetch all reports for a community (staff only - enforced by RLS)
  Future<Either<Failure, List<CommunityReport>>> fetchCommunityReports({
    required String communityId,
    String? statusFilter, // 'pending', 'resolved', 'dismissed', null = all
  });

  /// Fetch activity logs for a community (staff only)
  Future<Either<Failure, List<ActivityLog>>> fetchActivityLogs({
    required String communityId,
    String? actionTypeFilter, // 'CONTENT_REMOVED', null = all
    int limit = 50,
  });

  /// Resolve a report (mark as resolved with note)
  Future<Either<Failure, void>> resolveReport({
    required String reportId,
    required String resolutionNote,
  });

  /// Dismiss a report (mark as dismissed with note)
  Future<Either<Failure, void>> dismissReport({
    required String reportId,
    required String resolutionNote,
  });

  /// Delete content (post or comment) - triggers forensic log automatically
  Future<Either<Failure, void>> deleteContent({
    required String entityType, // 'post' or 'comment'
    required String entityId,
  });
}

// =============================================================================
// REPOSITORY IMPLEMENTATION
// =============================================================================

class CommunityModerationRepositoryImpl implements CommunityModerationRepository {
  final SupabaseClient _supabase;

  CommunityModerationRepositoryImpl(this._supabase);

  @override
  Future<Either<Failure, List<CommunityReport>>> fetchCommunityReports({
    required String communityId,
    String? statusFilter,
  }) async {
    try {
      print('🔍 Fetching community reports for: $communityId');

      // Build query with LEFT JOINs for reporter and accused profiles
      var query = _supabase
          .from('community_reports')
          .select('''
            *,
            reporter:users_global!reporter_id(username, avatar_global_url),
            accused:users_global!accused_id(username, avatar_global_url)
          ''')
          .eq('community_id', communityId);

      // Apply status filter if provided
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }

      // Execute query with ordering (critical first, then by date)
      final response = await query
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      print('📦 Fetched ${(response as List).length} reports');

      // Map to entities
      final reports = (response as List).map((json) {
        // Extract reporter data (can be null for AI reports)
        final reporterData = json['reporter'] as Map<String, dynamic>?;
        final accusedData = json['accused'] as Map<String, dynamic>?;

        return CommunityReport.fromJson({
          ...json,
          'reporter_username': reporterData?['username'],
          'reporter_avatar': reporterData?['avatar_global_url'],
          'accused_username': accusedData?['username'],
          'accused_avatar': accusedData?['avatar_global_url'],
        });
      }).toList();

      print('✅ Parsed ${reports.length} reports (${reports.where((r) => r.isAIReport).length} from AI)');

      return Right(reports);
    } catch (e, stackTrace) {
      print('❌ Error fetching community reports: $e');
      print('📍 Stack trace: $stackTrace');
      return Left(ServerFailure('Error cargando reportes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ActivityLog>>> fetchActivityLogs({
    required String communityId,
    String? actionTypeFilter,
    int limit = 50,
  }) async {
    try {
      print('🔍 Fetching activity logs for: $communityId');

      // Build query with LEFT JOINs for actor and target user profiles
      var query = _supabase
          .from('community_activity_logs')
          .select('''
            *,
            actor:users_global!actor_id(username, avatar_global_url),
            target:users_global!target_user_id(username, avatar_global_url)
          ''')
          .eq('community_id', communityId);

      // Apply action type filter if provided
      if (actionTypeFilter != null) {
        query = query.eq('action_type', actionTypeFilter);
      }

      // Execute query with ordering and limit
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      print('📦 Fetched ${(response as List).length} activity logs');

      // Map to entities
      final logs = (response as List).map((json) {
        final actorData = json['actor'] as Map<String, dynamic>?;
        final targetData = json['target'] as Map<String, dynamic>?;

        return ActivityLog.fromJson({
          ...json,
          'actor_username': actorData?['username'],
          'actor_avatar': actorData?['avatar_global_url'],
          'target_username': targetData?['username'],
          'target_avatar': targetData?['avatar_global_url'],
        });
      }).toList();

      print('✅ Parsed ${logs.length} activity logs (${logs.where((l) => l.isContentRemoval).length} content removals)');

      return Right(logs);
    } catch (e, stackTrace) {
      print('❌ Error fetching activity logs: $e');
      print('📍 Stack trace: $stackTrace');
      return Left(ServerFailure('Error cargando logs: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resolveReport({
    required String reportId,
    required String resolutionNote,
  }) async {
    try {
      print('✅ Resolving report: $reportId');

      await _supabase
          .from('community_reports')
          .update({
            'status': 'resolved',
            'resolution_note': resolutionNote,
          })
          .eq('id', reportId);

      print('✅ Report resolved successfully');
      return const Right(null);
    } catch (e) {
      print('❌ Error resolving report: $e');
      return Left(ServerFailure('Error resolviendo reporte: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> dismissReport({
    required String reportId,
    required String resolutionNote,
  }) async {
    try {
      print('❌ Dismissing report: $reportId');

      await _supabase
          .from('community_reports')
          .update({
            'status': 'dismissed',
            'resolution_note': resolutionNote,
          })
          .eq('id', reportId);

      print('✅ Report dismissed successfully');
      return const Right(null);
    } catch (e) {
      print('❌ Error dismissing report: $e');
      return Left(ServerFailure('Error descartando reporte: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContent({
    required String entityType,
    required String entityId,
  }) async {
    try {
      print('🗑️ Deleting $entityType: $entityId');

      // Determine table name
      final tableName = entityType == 'post' 
          ? 'community_wall_posts' 
          : 'wall_post_comments';

      // Delete from database (triggers will handle forensic logging)
      await _supabase
          .from(tableName)
          .delete()
          .eq('id', entityId);

      print('✅ Content deleted (forensic log created automatically by trigger)');
      return const Right(null);
    } on PostgrestException catch (e) {
      print('❌ Postgres error deleting content: ${e.message}');
      return Left(ServerFailure('Error borrando contenido: ${e.message}'));
    } catch (e) {
      print('❌ Error deleting content: $e');
      return Left(ServerFailure('Error borrando contenido: $e'));
    }
  }
}
