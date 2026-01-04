/// Project Neo - Community Title Entity
///
/// Represents a title/tag definition for a community (Amino-style)
library;

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Title style configuration
class TitleStyle extends Equatable {
  /// Background color hex (e.g., "1337EC")
  final String backgroundColor;
  
  /// Foreground/text color hex (e.g., "FFFFFF")
  final String foregroundColor;
  
  /// Optional icon name (e.g., "star", "crown")
  final String? iconName;

  const TitleStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.iconName,
  });

  /// Parse from JSONB style field
  factory TitleStyle.fromJson(Map<String, dynamic> json) {
    return TitleStyle(
      backgroundColor: json['bg'] as String? ?? 'CCCCCC',
      foregroundColor: json['fg'] as String? ?? '000000',
      iconName: json['icon'] as String?,
    );
  }

  /// Convert to Color objects
  Color get bgColor => Color(int.parse('FF$backgroundColor', radix: 16));
  Color get fgColor => Color(int.parse('FF$foregroundColor', radix: 16));

  @override
  List<Object?> get props => [backgroundColor, foregroundColor, iconName];
}

/// Community Title (template/definition)
class CommunityTitle extends Equatable {
  final String id;
  final String communityId;
  final String name;
  final String? slug;
  final String? description;
  final TitleStyle style;
  final int priority;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityTitle({
    required this.id,
    required this.communityId,
    required this.name,
    this.slug,
    this.description,
    required this.style,
    this.priority = 0,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        communityId,
        name,
        slug,
        description,
        style,
        priority,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
