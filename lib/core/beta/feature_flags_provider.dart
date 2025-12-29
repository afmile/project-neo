/// Project Neo - Feature Flags Provider
///
/// Centralized feature flags fetched from Supabase with local caching.
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FEATURE FLAGS MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Feature flags for beta control
class FeatureFlags {
  final bool enableFeed;
  final bool enablePosts;
  final bool enableChats;
  final bool enableQuizzes;
  final bool enableEconomy;
  final bool enableInvites;
  
  const FeatureFlags({
    this.enableFeed = false,
    this.enablePosts = false,
    this.enableChats = false,
    this.enableQuizzes = false,
    this.enableEconomy = false,
    this.enableInvites = false,
  });
  
  /// All flags disabled (safe fallback)
  static const FeatureFlags disabled = FeatureFlags();
  
  /// Create from JSON map
  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      enableFeed: json['enableFeed'] ?? false,
      enablePosts: json['enablePosts'] ?? false,
      enableChats: json['enableChats'] ?? false,
      enableQuizzes: json['enableQuizzes'] ?? false,
      enableEconomy: json['enableEconomy'] ?? false,
      enableInvites: json['enableInvites'] ?? false,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'enableFeed': enableFeed,
    'enablePosts': enablePosts,
    'enableChats': enableChats,
    'enableQuizzes': enableQuizzes,
    'enableEconomy': enableEconomy,
    'enableInvites': enableInvites,
  };
  
  @override
  String toString() => 'FeatureFlags(feed=$enableFeed, posts=$enablePosts, '
      'chats=$enableChats, quizzes=$enableQuizzes, economy=$enableEconomy, '
      'invites=$enableInvites)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

const _cacheKey = 'neo_feature_flags';
const _cacheMaxAge = Duration(hours: 1);
const _cacheTimestampKey = 'neo_feature_flags_timestamp';

class FeatureFlagsRepository {
  final SupabaseClient _client;
  
  FeatureFlagsRepository(this._client);
  
  /// Fetch feature flags with caching strategy:
  /// 1. Try Supabase
  /// 2. On success: update cache
  /// 3. On failure: use cache if valid
  /// 4. If no cache: return all disabled
  Future<FeatureFlags> getFeatureFlags() async {
    try {
      // Try fetch from Supabase
      final response = await _client
          .from('app_config')
          .select('value')
          .eq('key', 'feature_flags')
          .maybeSingle();
      
      if (response != null && response['value'] != null) {
        final flags = FeatureFlags.fromJson(response['value'] as Map<String, dynamic>);
        await _saveToCache(flags);
        return flags;
      }
    } catch (_) {
      // Supabase fetch failed, try cache
    }
    
    // Try cache
    final cached = await _loadFromCache();
    if (cached != null) {
      return cached;
    }
    
    // Fallback: all disabled
    return FeatureFlags.disabled;
  }
  
  Future<void> _saveToCache(FeatureFlags flags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(flags.toJson()));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Cache save failed, non-critical
    }
  }
  
  Future<FeatureFlags?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cached == null || timestamp == null) return null;
      
      // Check if cache is too old
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheMaxAge) {
        return null;
      }
      
      return FeatureFlags.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Repository provider
final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>((ref) {
  return FeatureFlagsRepository(Supabase.instance.client);
});

/// Feature flags provider - fetches from Supabase with caching
final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  final repository = ref.watch(featureFlagsRepositoryProvider);
  return repository.getFeatureFlags();
});

// ═══════════════════════════════════════════════════════════════════════════════
// CONVENIENCE PROVIDERS (for easy access to individual flags)
// ═══════════════════════════════════════════════════════════════════════════════

/// Check if feed feature is enabled
final isFeedEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).valueOrNull?.enableFeed ?? false;
});

/// Check if posts feature is enabled
final isPostsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).valueOrNull?.enablePosts ?? false;
});

/// Check if chats feature is enabled
final isChatsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).valueOrNull?.enableChats ?? false;
});

/// Check if quizzes feature is enabled
final isQuizzesEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).valueOrNull?.enableQuizzes ?? false;
});

/// Check if economy feature is enabled
final isEconomyEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).valueOrNull?.enableEconomy ?? false;
});

/// Check if invites feature is enabled
final isInvitesEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagsProvider).valueOrNull?.enableInvites ?? false;
});
