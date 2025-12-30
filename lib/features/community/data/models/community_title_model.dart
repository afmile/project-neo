/// Project Neo - Community Title Model
///
/// Data model for converting Supabase JSON to CommunityTitle entity
library;

import '../../domain/entities/community_title.dart';

class CommunityTitleModel {
  /// Convert from Supabase JSON to CommunityTitle entity
  static CommunityTitle fromSupabase(Map<String, dynamic> json) {
    return CommunityTitle(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      style: TitleStyle.fromJson(json['style'] as Map<String, dynamic>? ?? {}),
      priority: json['priority'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert list from Supabase
  static List<CommunityTitle> listFromSupabase(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Convert to Supabase JSON (for insert/update)
  static Map<String, dynamic> toSupabase(CommunityTitle title) {
    return {
      'community_id': title.communityId,
      'name': title.name,
      'slug': title.slug,
      'description': title.description,
      'style': {
        'bg': title.style.backgroundColor,
        'fg': title.style.foregroundColor,
        if (title.style.iconName != null) 'icon': title.style.iconName,
      },
      'priority': title.priority,
      'is_active': title.isActive,
      'created_by': title.createdBy,
    };
  }
}
