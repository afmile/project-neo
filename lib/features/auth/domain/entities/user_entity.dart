/// Project Neo - User Entity
///
/// Core user entity for the domain layer.
library;

import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user
class UserEntity extends Equatable {
  /// User's unique identifier (from auth.users)
  final String id;
  
  /// User's email address
  final String email;
  
  /// Username (unique)
  final String username;
  
  /// Display name (optional)
  final String? displayName;
  
  /// Avatar URL
  final String? avatarUrl;
  
  /// User bio/description
  final String? bio;
  
  /// Security clearance level (1-99, 99 = GOD MODE)
  final int clearanceLevel;
  
  /// Whether user is in incognito mode
  final bool isIncognito;
  
  /// User's NeoCoins balance
  final double neocoinsBalance;
  
  /// Whether user has VIP status
  final bool isVip;
  
  /// VIP expiry date (if VIP)
  final DateTime? vipExpiry;
  
  /// Whether user is a global administrator (can access all communities)
  final bool isGlobalAdmin;
  
  /// When the user was created
  final DateTime createdAt;
  
  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.clearanceLevel = 1,
    this.isIncognito = false,
    this.neocoinsBalance = 0,
    this.isVip = false,
    this.vipExpiry,
    this.isGlobalAdmin = false,
    required this.createdAt,
  });
  
  /// Check if user is an admin (level 75+)
  bool get isAdmin => clearanceLevel >= 75;
  
  /// Check if user is a moderator (level 50+)
  bool get isModerator => clearanceLevel >= 50;
  
  /// Check if user has GOD MODE (level 99)
  bool get isGodMode => clearanceLevel == 99 && !isIncognito;
  
  /// Get the visible clearance level (respects incognito)
  int get visibleClearanceLevel => isIncognito ? 1 : clearanceLevel;
  
  /// Check if VIP is currently active
  bool get isVipActive {
    if (!isVip) return false;
    if (vipExpiry == null) return true;
    return vipExpiry!.isAfter(DateTime.now());
  }
  
  /// Alias for chat pinning logic (NeoVip = active VIP)
  bool get isNeoVip => isVipActive;
  
  /// Create a copy with modified fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? clearanceLevel,
    bool? isIncognito,
    double? neocoinsBalance,
    bool? isVip,
    DateTime? vipExpiry,
    bool? isGlobalAdmin,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      clearanceLevel: clearanceLevel ?? this.clearanceLevel,
      isIncognito: isIncognito ?? this.isIncognito,
      neocoinsBalance: neocoinsBalance ?? this.neocoinsBalance,
      isVip: isVip ?? this.isVip,
      vipExpiry: vipExpiry ?? this.vipExpiry,
      isGlobalAdmin: isGlobalAdmin ?? this.isGlobalAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    username,
    displayName,
    avatarUrl,
    bio,
    clearanceLevel,
    isIncognito,
    neocoinsBalance,
    isVip,
    vipExpiry,
    isGlobalAdmin,
    createdAt,
  ];
}
