/// Project Neo - Member Title Model
///
/// Data model for converting Supabase JSON to MemberTitle entity
library;

import '../../domain/entities/member_title.dart';
import '../../domain/entities/community_title.dart';
import 'community_title_model.dart';

class MemberTitleModel {
  /// Convert from Supabase JSON to MemberTitle entity
  /// Requires joined 'title' data from community_titles
  static MemberTitle fromSupabase(Map<String, dynamic> json) {
    // Parse the joined title data
    final titleData = json['title'] as Map<String, dynamic>?;
    if (titleData == null) {
      throw Exception('Member title requires joined title data');
    }

    final title = CommunityTitleModel.fromSupabase(titleData);

    return MemberTitle(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      memberUserId: json['member_user_id'] as String,
      title: title,
      assignedBy: json['assigned_by'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Convert list from Supabase
  static List<MemberTitle> listFromSupabase(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Convert to Supabase JSON (for insert/update)
  static Map<String, dynamic> toSupabase(MemberTitle memberTitle) {
    return {
      'community_id': memberTitle.communityId,
      'member_user_id': memberTitle.memberUserId,
      'title_id': memberTitle.title.id,
      'assigned_by': memberTitle.assignedBy,
      'assigned_at': memberTitle.assignedAt.toIso8601String(),
      'expires_at': memberTitle.expiresAt?.toIso8601String(),
      'is_active': memberTitle.isActive,
      'sort_order': memberTitle.sortOrder,
    };
  }
}
