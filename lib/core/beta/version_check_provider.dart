/// Project Neo - Version Check Provider
///
/// Checks if the current app version meets minimum requirements.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// VERSION CONFIG MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Minimum version configuration from Supabase
class VersionConfig {
  final String minVersion;
  final String message;
  
  const VersionConfig({
    required this.minVersion,
    this.message = 'Por favor actualiza la app para continuar',
  });
  
  /// Default (no update required)
  static const VersionConfig none = VersionConfig(minVersion: '0.0.0');
  
  factory VersionConfig.fromJson(Map<String, dynamic> json) {
    return VersionConfig(
      minVersion: json['version'] ?? '0.0.0',
      message: json['message'] ?? 'Por favor actualiza la app para continuar',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Fetch minimum required version from Supabase
final minVersionConfigProvider = FutureProvider<VersionConfig>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', 'min_app_version')
        .maybeSingle();
    
    if (response == null || response['value'] == null) {
      return VersionConfig.none;
    }
    
    return VersionConfig.fromJson(response['value'] as Map<String, dynamic>);
  } catch (_) {
    // Error fetching - allow app to continue
    return VersionConfig.none;
  }
});

/// Check if current version is blocked
final isVersionBlockedProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(minVersionConfigProvider);
  final config = configAsync.valueOrNull ?? VersionConfig.none;
  
  return _compareVersions(EnvConfig.appVersion, config.minVersion) < 0;
});

/// Get update message
final updateMessageProvider = Provider<String>((ref) {
  final configAsync = ref.watch(minVersionConfigProvider);
  return configAsync.valueOrNull?.message ?? 'Por favor actualiza la app';
});

// ═══════════════════════════════════════════════════════════════════════════════
// VERSION COMPARISON
// ═══════════════════════════════════════════════════════════════════════════════

/// Compare two semantic version strings
/// Returns: negative if a < b, 0 if equal, positive if a > b
int _compareVersions(String a, String b) {
  final aParts = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final bParts = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  
  // Pad to same length
  while (aParts.length < 3) {
    aParts.add(0);
  }
  while (bParts.length < 3) {
    bParts.add(0);
  }
  
  for (int i = 0; i < 3; i++) {
    if (aParts[i] < bParts[i]) return -1;
    if (aParts[i] > bParts[i]) return 1;
  }
  
  return 0;
}
