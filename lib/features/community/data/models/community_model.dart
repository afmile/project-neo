/// Project Neo - Community Model
///
/// Supabase data model for communities.
library;

import '../../domain/entities/community_entity.dart';
import '../../domain/entities/community_tab_entity.dart';

/// Community data model for Supabase
class CommunityModel extends CommunityEntity {
  const CommunityModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.slug,
    super.description,
    super.iconUrl,
    super.bannerUrl,
    super.theme,
    super.isNsfw,
    super.status,
    super.memberCount,
    super.isPrivate,
    super.inviteOnly,
    super.tabs,
    super.categoryIds,
    super.language = 'es',
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from Supabase JSON
  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    // Parse tabs if included
    final tabsJson = json['community_tabs'] as List<dynamic>?;
    final tabs = tabsJson?.map((t) => CommunityTabModel.fromJson(t as Map<String, dynamic>)).toList() ?? [];
    
    // Parse categories if included (assuming array of strings or view)
    final categories = (json['category_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return CommunityModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      theme: json['theme_config'] != null
          ? CommunityTheme.fromJson(json['theme_config'] as Map<String, dynamic>)
          : const CommunityTheme(),
      isNsfw: json['is_nsfw_flag'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      memberCount: json['member_count'] as int? ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
      inviteOnly: json['invite_only'] as bool? ?? false,
      tabs: tabs,
      categoryIds: categories,
      language: json['language'] as String? ?? 'es',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'title': title,
    'slug': slug,
    'description': description,
    'icon_url': iconUrl,
    'banner_url': bannerUrl,
    'theme_config': theme.toJson(),
    'is_nsfw_flag': isNsfw,
    'status': status.name,
    'is_private': isPrivate,
    'invite_only': inviteOnly,
    'language': language,
  };


  /// For creating new community
  Map<String, dynamic> toInsertJson() => {
    'owner_id': ownerId,
    'title': title,
    'slug': slug,
    'description': description,
    'icon_url': iconUrl,
    'banner_url': bannerUrl,
    'theme_config': theme.toJson(),
    'is_nsfw_flag': isNsfw,
    'is_private': isPrivate,
    'invite_only': inviteOnly,
    'language': language,
  };

  static CommunityStatus _parseStatus(String? status) {
    switch (status) {
      case 'shadowbanned':
        return CommunityStatus.shadowbanned;
      case 'suspended':
        return CommunityStatus.suspended;
      case 'archived':
        return CommunityStatus.archived;
      default:
        return CommunityStatus.active;
    }
  }
}

/// Community Tab data model
class CommunityTabModel extends CommunityTabEntity {
  const CommunityTabModel({
    required super.id,
    required super.communityId,
    required super.type,
    required super.label,
    super.icon,
    super.sortOrder,
    super.isEnabled,
    super.config,
  });

  factory CommunityTabModel.fromJson(Map<String, dynamic> json) {
    return CommunityTabModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      type: _parseTabType(json['tab_type'] as String),
      label: json['label'] as String,
      icon: json['icon'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isEnabled: json['is_enabled'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'community_id': communityId,
    'tab_type': type.name,
    'label': label,
    'icon': icon,
    'sort_order': sortOrder,
    'is_enabled': isEnabled,
    'config': config,
  };

  static CommunityTabType _parseTabType(String type) {
    return CommunityTabType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => CommunityTabType.feed,
    );
  }
}
