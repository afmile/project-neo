/// Project Neo - Title Request Model
///
/// Data model for converting between Supabase JSON and TitleRequest entity
library;

import '../../domain/entities/title_request.dart';

class TitleRequestModel {
  /// Convert from Supabase JSON to TitleRequest entity
  static TitleRequest fromSupabase(Map<String, dynamic> json) {
    return TitleRequest(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      memberUserId: json['member_user_id'] as String,
      titleText: json['title_text'] as String,
      textColor: json['text_color'] as String,
      backgroundColor: json['background_color'] as String,
      status: TitleRequestStatus.fromJson(json['status'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert list from Supabase JSON
  static List<TitleRequest> listFromSupabase(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Convert TitleRequest entity to Supabase JSON (for insert)
  static Map<String, dynamic> toSupabase(TitleRequest request) {
    return {
      'community_id': request.communityId,
      'member_user_id': request.memberUserId,
      'title_text': request.titleText,
      'text_color': request.textColor,
      'background_color': request.backgroundColor,
      'status': request.status.toJson(),
      if (request.reviewedBy != null) 'reviewed_by': request.reviewedBy,
      if (request.reviewedAt != null)
        'reviewed_at': request.reviewedAt!.toIso8601String(),
    };
  }

  /// Convert for creating a new request (minimal fields)
  static Map<String, dynamic> toSupabaseInsert({
    required String communityId,
    required String memberUserId,
    required String titleText,
    required String textColor,
    required String backgroundColor,
  }) {
    return {
      'community_id': communityId,
      'member_user_id': memberUserId,
      'title_text': titleText,
      'text_color': textColor,
      'background_color': backgroundColor,
      'status': 'pending',
    };
  }
}
