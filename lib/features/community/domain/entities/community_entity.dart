/// Project Neo - Community Entity
///
/// Core community domain entity.
library;

import 'package:equatable/equatable.dart';
import 'community_tab_entity.dart';

/// Community status enum
enum CommunityStatus { active, shadowbanned, suspended, archived }

/// Community entity for the domain layer
class CommunityEntity extends Equatable {
  final String id;
  final String ownerId;
  final String title;
  final String slug;
  final String? description;
  final String? iconUrl;
  final String? bannerUrl;
  final CommunityTheme theme;
  final bool isNsfw;
  final CommunityStatus status;
  final int memberCount;
  final bool isPrivate;
  final bool inviteOnly;
  final List<CommunityTabEntity> tabs;
  final List<String> categoryIds;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? currentUserRole; // Added for UI filtering (owner, leader, moderator, member)

  const CommunityEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.slug,
    this.description,
    this.iconUrl,
    this.bannerUrl,
    this.theme = const CommunityTheme(),
    this.isNsfw = false,
    this.status = CommunityStatus.active,
    this.memberCount = 0,
    this.isPrivate = false,
    this.inviteOnly = false,
    this.tabs = const [],
    this.categoryIds = const [],
    this.language = 'es',
    required this.createdAt,
    required this.updatedAt,
    this.currentUserRole,
  });

  /// Get the primary accent color for this community
  String get accentColor => theme.accentColor;

  /// Check if current user is owner
  bool isOwner(String userId) => ownerId == userId;

  /// Check if current user has staff privileges (Owner, Leader, Moderator)
  bool get isStaff {
    if (currentUserRole == 'owner') return true;
    if (currentUserRole == 'leader') return true;
    if (currentUserRole == 'moderator') return true;
    return false;
  }

  @override
  List<Object?> get props => [
    id, ownerId, title, slug, description, iconUrl, bannerUrl,
    theme, isNsfw, status, memberCount, isPrivate, inviteOnly,
    tabs, categoryIds, language, createdAt, updatedAt, currentUserRole,
  ];
}

/// Community theme configuration
class CommunityTheme extends Equatable {
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final bool darkMode;

  const CommunityTheme({
    this.primaryColor = '#6366f1',
    this.secondaryColor = '#8b5cf6',
    this.accentColor = '#a855f7',
    this.darkMode = true,
  });

  factory CommunityTheme.fromJson(Map<String, dynamic> json) {
    return CommunityTheme(
      primaryColor: json['primary_color'] as String? ?? '#6366f1',
      secondaryColor: json['secondary_color'] as String? ?? '#8b5cf6',
      accentColor: json['accent_color'] as String? ?? '#a855f7',
      darkMode: json['dark_mode'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
    'accent_color': accentColor,
    'dark_mode': darkMode,
  };

  @override
  List<Object?> get props => [primaryColor, secondaryColor, accentColor, darkMode];
}
