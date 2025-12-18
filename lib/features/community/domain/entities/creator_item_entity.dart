/// Project Neo - Creator Item Entity
///
/// Marketplace items created by users.
library;

import 'package:equatable/equatable.dart';

/// Types of creator items
enum CreatorItemType {
  frame,
  bubble,
  badge,
  effect,
  stickerPack,
}

/// Creator marketplace item entity
class CreatorItemEntity extends Equatable {
  final String id;
  final String creatorId;
  final String? creatorUsername;
  final CreatorItemType type;
  final String name;
  final String? description;
  final String? previewUrl;
  final Map<String, dynamic> assetData;
  final int priceNeocoins;
  final bool isApproved;
  final int salesCount;
  final double revenueTotal;
  final DateTime createdAt;

  const CreatorItemEntity({
    required this.id,
    required this.creatorId,
    this.creatorUsername,
    required this.type,
    required this.name,
    this.description,
    this.previewUrl,
    required this.assetData,
    this.priceNeocoins = 100,
    this.isApproved = false,
    this.salesCount = 0,
    this.revenueTotal = 0,
    required this.createdAt,
  });

  /// Get type display name
  String get typeDisplayName {
    switch (type) {
      case CreatorItemType.frame:
        return 'Marco';
      case CreatorItemType.bubble:
        return 'Burbuja';
      case CreatorItemType.badge:
        return 'Insignia';
      case CreatorItemType.effect:
        return 'Efecto';
      case CreatorItemType.stickerPack:
        return 'Pack de Stickers';
    }
  }

  /// Creator's earnings (70% of revenue, platform takes 30%)
  double get creatorEarnings => revenueTotal * 0.7;

  @override
  List<Object?> get props => [
    id, creatorId, type, name, description, previewUrl,
    assetData, priceNeocoins, isApproved, salesCount,
    revenueTotal, createdAt,
  ];
}
