/// Project Neo - User Model
///
/// Data transfer object for user data from Supabase.
library;

import '../../domain/entities/user_entity.dart';

/// User model for data layer - handles JSON serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.displayName,
    super.avatarUrl,
    super.bio,
    super.clearanceLevel,
    super.isIncognito,
    super.neocoinsBalance,
    super.isVip,
    super.vipExpiry,
    super.isGlobalAdmin,
    required super.createdAt,
  });
  
  /// Create UserModel from Supabase auth user + profile data
  factory UserModel.fromSupabase({
    required String id,
    required String email,
    Map<String, dynamic>? userGlobal,
    Map<String, dynamic>? securityProfile,
    Map<String, dynamic>? wallet,
  }) {
    return UserModel(
      id: id,
      email: email,
      username: userGlobal?['username'] ?? 'user_${id.substring(0, 8)}',
      displayName: userGlobal?['display_name'],
      avatarUrl: userGlobal?['avatar_global_url'],
      bio: userGlobal?['bio'],
      clearanceLevel: securityProfile?['clearance_level'] ?? 1,
      isIncognito: securityProfile?['is_incognito'] ?? false,
      neocoinsBalance: (wallet?['neocoins_balance'] ?? 0).toDouble(),
      isVip: wallet?['is_vip'] ?? false,
      vipExpiry: wallet?['vip_expiry'] != null 
          ? DateTime.parse(wallet!['vip_expiry']) 
          : null,
      isGlobalAdmin: userGlobal?['is_global_admin'] ?? false,
      createdAt: userGlobal?['created_at'] != null
          ? DateTime.parse(userGlobal!['created_at'])
          : DateTime.now(),
    );
  }
  
  /// Create UserModel from JSON map (combined data)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_global_url'],
      bio: json['bio'],
      clearanceLevel: json['clearance_level'] ?? 1,
      isIncognito: json['is_incognito'] ?? false,
      neocoinsBalance: (json['neocoins_balance'] ?? 0).toDouble(),
      isVip: json['is_vip'] ?? false,
      vipExpiry: json['vip_expiry'] != null 
          ? DateTime.parse(json['vip_expiry']) 
          : null,
      isGlobalAdmin: json['is_global_admin'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_global_url': avatarUrl,
      'bio': bio,
      'clearance_level': clearanceLevel,
      'is_incognito': isIncognito,
      'neocoins_balance': neocoinsBalance,
      'is_vip': isVip,
      'vip_expiry': vipExpiry?.toIso8601String(),
      'is_global_admin': isGlobalAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Convert entity to model
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      username: entity.username,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      bio: entity.bio,
      clearanceLevel: entity.clearanceLevel,
      isIncognito: entity.isIncognito,
      neocoinsBalance: entity.neocoinsBalance,
      isVip: entity.isVip,
      vipExpiry: entity.vipExpiry,
      isGlobalAdmin: entity.isGlobalAdmin,
      createdAt: entity.createdAt,
    );
  }
}
