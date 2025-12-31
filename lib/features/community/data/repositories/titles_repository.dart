/// Project Neo - Titles Repository
///
/// Handles all database operations for community titles and member title assignments
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_title.dart';
import '../../domain/entities/member_title.dart';
import '../../domain/entities/title_request.dart';
import '../models/community_title_model.dart';
import '../models/member_title_model.dart';
import '../models/title_request_model.dart';

class TitlesRepository {
  final SupabaseClient _supabase;

  TitlesRepository(this._supabase);

  // ═════════════════════════════════════════════════════════════════════════
  // FETCH OPERATIONS
  // ═════════════════════════════════════════════════════════════════════════

  /// Fetch all active titles for a user in a specific community
  /// 
  /// Returns titles sorted by: sort_order ASC, priority DESC, assigned_at DESC
  /// Filters out expired and inactive titles
  Future<List<MemberTitle>> fetchUserTitles({
    required String userId,
    required String communityId,
  }) async {
    try {
      final response = await _supabase
          .from('community_member_titles')
          .select('''
            *,
            title:community_titles(*)
          ''')
          .eq('member_user_id', userId)
          .eq('community_id', communityId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final memberTitles = MemberTitleModel.listFromSupabase(response as List<dynamic>);

      // Filter out expired titles and sort by priority
      final validTitles = memberTitles
          .where((mt) => !mt.isExpired)
          .toList()
        ..sort((a, b) {
          // First by sort_order
          final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
          if (sortOrderCompare != 0) return sortOrderCompare;
          
          // Then by priority (higher first)
          final priorityCompare = b.title.priority.compareTo(a.title.priority);
          if (priorityCompare != 0) return priorityCompare;
          
          // Finally by assigned_at (newer first)
          return b.assignedAt.compareTo(a.assignedAt);
        });

      return validTitles;
    } catch (e) {
      print('❌ ERROR fetchUserTitles: $e');
      return [];
    }
  }

  /// Fetch all available titles for a community (for admin/selection UI)
  Future<List<CommunityTitle>> fetchCommunityTitles({
    required String communityId,
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('community_titles')
          .select()
          .eq('community_id', communityId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('priority', ascending: false);

      return CommunityTitleModel.listFromSupabase(response as List<dynamic>);
    } catch (e) {
      print('❌ ERROR fetchCommunityTitles: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ASSIGNMENT OPERATIONS (Admin/Leader only)
  // ═════════════════════════════════════════════════════════════════════════

  /// Assign a title to a user
  /// 
  /// Returns the created MemberTitle or null on failure
  Future<MemberTitle?> assignTitle({
    required String userId,
    required String titleId,
    required String communityId,
    DateTime? expiresAt,
    int sortOrder = 0,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ ERROR assignTitle: No authenticated user');
        return null;
      }

      final response = await _supabase
          .from('community_member_titles')
          .insert({
            'community_id': communityId,
            'member_user_id': userId,
            'title_id': titleId,
            'assigned_by': currentUserId,
            'expires_at': expiresAt?.toIso8601String(),
            'sort_order': sortOrder,
          })
          .select('''
            *,
            title:community_titles(*)
          ''')
          .single();

      return MemberTitleModel.fromSupabase(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ ERROR assignTitle: $e');
      return null;
    }
  }

  /// Remove a title assignment (soft delete by setting is_active to false)
  Future<bool> removeTitle({
    required String assignmentId,
  }) async {
    try {
      await _supabase
          .from('community_member_titles')
          .update({'is_active': false})
          .eq('id', assignmentId);

      return true;
    } catch (e) {
      print('❌ ERROR removeTitle: $e');
      return false;
    }
  }

  /// Hard delete a title assignment (use sparingly)
  Future<bool> deleteTitle({
    required String assignmentId,
  }) async {
    try {
      await _supabase
          .from('community_member_titles')
          .delete()
          .eq('id', assignmentId);

      return true;
    } catch (e) {
      print('❌ ERROR deleteTitle: $e');
      return false;
    }
  }

  /// Update title assignment sort order
  Future<bool> updateTitleSortOrder({
    required String assignmentId,
    required int newSortOrder,
  }) async {
    try {
      await _supabase
          .from('community_member_titles')
          .update({'sort_order': newSortOrder})
          .eq('id', assignmentId);

      return true;
    } catch (e) {
      print('❌ ERROR updateTitleSortOrder: $e');
      return false;
    }
  }

  /// Update title visibility (user can hide/show their own titles)
  Future<bool> updateTitleVisibility({
    required String assignmentId,
    required bool isVisible,
  }) async {
    try {
      await _supabase
          .from('community_member_titles')
          .update({'is_visible': isVisible})
          .eq('id', assignmentId);

      return true;
    } catch (e) {
      print('❌ ERROR updateTitleVisibility: $e');
      return false;
    }
  }

  /// Batch update multiple title sort orders
  /// 
  /// This is more efficient than calling updateTitleSortOrder multiple times
  /// when reordering titles via drag-and-drop
  Future<bool> batchUpdateTitleOrders({
    required List<({String id, int order})> updates,
  }) async {
    try {
      // Supabase doesn't support batch updates directly, so we do them sequentially
      // In a production app, you might want to use a stored procedure for this
      for (final update in updates) {
        await _supabase
            .from('community_member_titles')
            .update({'sort_order': update.order})
            .eq('id', update.id);
      }

      return true;
    } catch (e) {
      print('❌ ERROR batchUpdateTitleOrders: $e');
      return false;
    }
  }

  /// Fetch all user titles including hidden ones (for settings screen)
  Future<List<MemberTitle>> fetchUserTitlesWithHidden({
    required String userId,
    required String communityId,
  }) async {
    try {
      final response = await _supabase
          .from('community_member_titles')
          .select('''
            *,
            title:community_titles(*)
          ''')
          .eq('member_user_id', userId)
          .eq('community_id', communityId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final memberTitles = MemberTitleModel.listFromSupabase(response as List<dynamic>);

      // Filter out expired titles and sort
      final validTitles = memberTitles
          .where((mt) => !mt.isExpired)
          .toList()
        ..sort((a, b) {
          // First by sort_order
          final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
          if (sortOrderCompare != 0) return sortOrderCompare;
          
          // Then by priority (higher first)
          final priorityCompare = b.title.priority.compareTo(a.title.priority);
          if (priorityCompare != 0) return priorityCompare;
          
          // Finally by assigned_at (newer first)
          return b.assignedAt.compareTo(a.assignedAt);
        });

      return validTitles;
    } catch (e) {
      print('❌ ERROR fetchUserTitlesWithHidden: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TITLE MANAGEMENT (Admin/Leader only)
  // ═════════════════════════════════════════════════════════════════════════

  /// Create a new title for a community
  Future<CommunityTitle?> createTitle({
    required String communityId,
    required String name,
    String? slug,
    String? description,
    required String backgroundColor,
    required String foregroundColor,
    String? iconName,
    int priority = 0,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ ERROR createTitle: No authenticated user');
        return null;
      }

      final response = await _supabase
          .from('community_titles')
          .insert({
            'community_id': communityId,
            'name': name,
            'slug': slug,
            'description': description,
            'style': {
              'bg': backgroundColor,
              'fg': foregroundColor,
              if (iconName != null) 'icon': iconName,
            },
            'priority': priority,
            'created_by': currentUserId,
          })
          .select()
          .single();

      return CommunityTitleModel.fromSupabase(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ ERROR createTitle: $e');
      return null;
    }
  }

  /// Update an existing title
  Future<bool> updateTitle({
    required String titleId,
    String? name,
    String? slug,
    String? description,
    String? backgroundColor,
    String? foregroundColor,
    String? iconName,
    int? priority,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (name != null) updates['name'] = name;
      if (slug != null) updates['slug'] = slug;
      if (description != null) updates['description'] = description;
      if (priority != null) updates['priority'] = priority;
      if (isActive != null) updates['is_active'] = isActive;
      
      if (backgroundColor != null || foregroundColor != null || iconName != null) {
        // Fetch current style first
        final current = await _supabase
            .from('community_titles')
            .select('style')
            .eq('id', titleId)
            .single();
        
        final currentStyle = current['style'] as Map<String, dynamic>? ?? {};
        
        updates['style'] = {
          'bg': backgroundColor ?? currentStyle['bg'] ?? 'CCCCCC',
          'fg': foregroundColor ?? currentStyle['fg'] ?? '000000',
          if (iconName != null) 'icon': iconName
          else if (currentStyle['icon'] != null) 'icon': currentStyle['icon'],
        };
      }

      if (updates.isEmpty) {
        print('⚠️ WARNING updateTitle: No fields to update');
        return false;
      }

      await _supabase
          .from('community_titles')
          .update(updates)
          .eq('id', titleId);

      return true;
    } catch (e) {
      print('❌ ERROR updateTitle: $e');
      return false;
    }
  }

  /// Delete a title (soft delete by setting is_active to false)
  Future<bool> deactivateTitle({
    required String titleId,
  }) async {
    try {
      await _supabase
          .from('community_titles')
          .update({'is_active': false})
          .eq('id', titleId);

      return true;
    } catch (e) {
      print('❌ ERROR deactivateTitle: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TITLE REQUESTS OPERATIONS
  // ═════════════════════════════════════════════════════════════════════════

  /// Create a new title request
  /// 
  /// Member proposes a custom title that requires leader approval
  Future<TitleRequest?> createTitleRequest({
    required String communityId,
    required String userId,
    required String titleText,
    required String textColor,
    required String backgroundColor,
  }) async {
    try {
      final data = TitleRequestModel.toSupabaseInsert(
        communityId: communityId,
        memberUserId: userId,
        titleText: titleText,
        textColor: textColor,
        backgroundColor: backgroundColor,
      );

      final response = await _supabase
          .from('title_requests')
          .insert(data)
          .select()
          .single();

      return TitleRequestModel.fromSupabase(response);
    } catch (e) {
      print('❌ ERROR createTitleRequest: $e');
      return null;
    }
  }

  /// Fetch all title requests for a specific user in a community
  /// 
  /// Returns requests ordered by creation date (newest first)
  Future<List<TitleRequest>> fetchUserTitleRequests({
    required String userId,
    required String communityId,
  }) async {
    try {
      final response = await _supabase
          .from('title_requests')
          .select()
          .eq('member_user_id', userId)
          .eq('community_id', communityId)
          .order('created_at', ascending: false);

      return TitleRequestModel.listFromSupabase(response as List<dynamic>);
    } catch (e) {
      print('❌ ERROR fetchUserTitleRequests: $e');
      return [];
    }
  }

  /// Fetch all pending title requests for a community
  /// 
  /// Only accessible by leaders (enforced by RLS)
  Future<List<TitleRequest>> fetchPendingTitleRequests({
    required String communityId,
  }) async {
    try {
      final response = await _supabase
          .from('title_requests')
          .select()
          .eq('community_id', communityId)
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return TitleRequestModel.listFromSupabase(response as List<dynamic>);
    } catch (e) {
      print('❌ ERROR fetchPendingTitleRequests: $e');
      return [];
    }
  }

  /// Approve a title request
  /// 
  /// Creates a new title in community_titles and assigns it to the member
  /// Updates the request status to 'approved'
  Future<bool> approveTitleRequest({
    required String requestId,
    required String leaderId,
  }) async {
    try {
      // 1. Fetch the request
      final requestResponse = await _supabase
          .from('title_requests')
          .select()
          .eq('id', requestId)
          .single();

      final request = TitleRequestModel.fromSupabase(requestResponse);

      // 2. Create title in community_titles
      final titleData = {
        'community_id': request.communityId,
        'name': request.titleText,
        'slug': _generateSlug(request.titleText),
        'description': 'Custom title created from member request',
        'style': {
          'bg': request.backgroundColor,
          'fg': request.textColor,
        },
        'priority': 0,
        'is_active': true,
        'created_by': leaderId,
      };

      final titleResponse = await _supabase
          .from('community_titles')
          .insert(titleData)
          .select()
          .single();

      final titleId = titleResponse['id'] as String;

      // 3. Assign title to member
      final assignmentData = {
        'community_id': request.communityId,
        'member_user_id': request.memberUserId,
        'title_id': titleId,
        'assigned_by': leaderId,
        'is_active': true,
        'sort_order': 0,
      };

      await _supabase
          .from('community_member_titles')
          .insert(assignmentData);

      // 4. Update request status
      await _supabase
          .from('title_requests')
          .update({
            'status': 'approved',
            'reviewed_by': leaderId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      print('✅ Title request approved and title assigned');
      return true;
    } catch (e) {
      print('❌ ERROR approveTitleRequest: $e');
      return false;
    }
  }

  /// Reject a title request
  /// 
  /// Updates the request status to 'rejected'
  Future<bool> rejectTitleRequest({
    required String requestId,
    required String leaderId,
  }) async {
    try {
      await _supabase
          .from('title_requests')
          .update({
            'status': 'rejected',
            'reviewed_by': leaderId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      print('✅ Title request rejected');
      return true;
    } catch (e) {
      print('❌ ERROR rejectTitleRequest: $e');
      return false;
    }
  }

  /// Delete a pending title request
  /// 
  /// Only the requesting member can delete their own pending requests
  Future<bool> deleteTitleRequest({
    required String requestId,
  }) async {
    try {
      await _supabase
          .from('title_requests')
          .delete()
          .eq('id', requestId);

      print('✅ Title request deleted');
      return true;
    } catch (e) {
      print('❌ ERROR deleteTitleRequest: $e');
      return false;
    }
  }

  /// Generate a slug from title text
  String _generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

