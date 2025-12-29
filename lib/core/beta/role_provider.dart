/// Project Neo - Role Provider
///
/// User role detection for UI-level permissions.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// USER ROLE ENUM
// ═══════════════════════════════════════════════════════════════════════════════

/// User roles for UI permissions
enum UserRole {
  /// Admin user (clearance level >= 5)
  admin,
  
  /// Regular member
  member,
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROLE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Determines user role based on clearance level
/// Admin: clearanceLevel >= 5
/// Member: default
final userRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(authProvider).user;
  
  if (user == null) return UserRole.member;
  
  // Clearance level 5+ = admin
  if (user.clearanceLevel >= 5) {
    return UserRole.admin;
  }
  
  return UserRole.member;
});

/// Check if current user is admin
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.admin;
});
