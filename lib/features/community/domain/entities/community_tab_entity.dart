/// Project Neo - Community Tab Entity
///
/// Dynamic tab configuration for communities.
library;

import 'package:equatable/equatable.dart';

/// Tab types available for communities
enum CommunityTabType {
  chat,
  feed,
  wiki,
  links,
  store,
  events,
  media,
}

/// Community tab entity
class CommunityTabEntity extends Equatable {
  final String id;
  final String communityId;
  final CommunityTabType type;
  final String label;
  final String? icon;
  final int sortOrder;
  final bool isEnabled;
  final Map<String, dynamic> config;

  const CommunityTabEntity({
    required this.id,
    required this.communityId,
    required this.type,
    required this.label,
    this.icon,
    this.sortOrder = 0,
    this.isEnabled = true,
    this.config = const {},
  });

  /// Get icon data for this tab type
  String get defaultIcon {
    switch (type) {
      case CommunityTabType.chat:
        return 'chat_bubble_outline';
      case CommunityTabType.feed:
        return 'dynamic_feed';
      case CommunityTabType.wiki:
        return 'menu_book';
      case CommunityTabType.links:
        return 'link';
      case CommunityTabType.store:
        return 'storefront';
      case CommunityTabType.events:
        return 'event';
      case CommunityTabType.media:
        return 'perm_media';
    }
  }

  @override
  List<Object?> get props => [
    id, communityId, type, label, icon, sortOrder, isEnabled, config,
  ];
}
