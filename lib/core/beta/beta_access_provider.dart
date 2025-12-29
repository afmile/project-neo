/// Project Neo - Beta Access Provider
///
/// Controls access to the closed beta based on user allowlist.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BETA ACCESS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Check if current user is a beta user
/// Returns true if user has is_beta_user = true in users_global
final isBetaUserProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  
  // Not authenticated - not a beta user
  if (userId == null) return false;
  
  try {
    final response = await Supabase.instance.client
        .from('users_global')
        .select('is_beta_user')
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return false;
    return response['is_beta_user'] == true;
  } catch (_) {
    // Error fetching - default to false for safety
    // This prevents non-beta users from accessing if DB is down
    return false;
  }
});

/// Convenience provider for synchronous access (with loading state)
final betaAccessStateProvider = Provider<BetaAccessState>((ref) {
  final asyncValue = ref.watch(isBetaUserProvider);
  
  return asyncValue.when(
    data: (isBeta) => isBeta ? BetaAccessState.allowed : BetaAccessState.denied,
    loading: () => BetaAccessState.loading,
    error: (_, __) => BetaAccessState.denied,
  );
});

/// Beta access state enum
enum BetaAccessState {
  loading,
  allowed,
  denied,
}
