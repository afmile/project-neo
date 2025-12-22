/// Project Neo - Draft Service
///
/// Auto-save drafts locally using SharedPreferences.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/community/domain/entities/post_entity.dart';

/// Draft data container
class DraftData {
  final String title;
  final String content;
  final String? coverImageUrl;
  final List<String>? pollOptions;
  final PostType postType;
  final DateTime savedAt;

  const DraftData({
    required this.title,
    required this.content,
    this.coverImageUrl,
    this.pollOptions,
    required this.postType,
    required this.savedAt,
  });

  factory DraftData.fromJson(Map<String, dynamic> json) {
    return DraftData(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      pollOptions: (json['poll_options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      postType: PostType.fromString(json['post_type'] as String?),
      savedAt: DateTime.parse(json['saved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'cover_image_url': coverImageUrl,
    'poll_options': pollOptions,
    'post_type': postType.dbValue,
    'saved_at': savedAt.toIso8601String(),
  };
  
  /// Check if draft has meaningful content
  bool get hasContent => title.isNotEmpty || content.isNotEmpty;
}

/// Service for managing content drafts
class DraftService {
  static const _keyPrefix = 'draft';
  
  final SharedPreferences _prefs;
  
  DraftService(this._prefs);
  
  /// Build storage key
  /// Format: draft_{userId}_{communityId}_{contentType}
  String _buildKey(String userId, String communityId, PostType type) =>
    '${_keyPrefix}_${userId}_${communityId}_${type.dbValue}';
  
  /// Save draft with debounce (caller should handle debouncing)
  Future<void> saveDraft({
    required String userId,
    required String communityId,
    required PostType type,
    required String title,
    required String content,
    String? coverImageUrl,
    List<String>? pollOptions,
  }) async {
    final key = _buildKey(userId, communityId, type);
    
    final draft = DraftData(
      title: title,
      content: content,
      coverImageUrl: coverImageUrl,
      pollOptions: pollOptions,
      postType: type,
      savedAt: DateTime.now(),
    );
    
    await _prefs.setString(key, jsonEncode(draft.toJson()));
  }
  
  /// Get existing draft
  Future<DraftData?> getDraft({
    required String userId,
    required String communityId,
    required PostType type,
  }) async {
    final key = _buildKey(userId, communityId, type);
    final json = _prefs.getString(key);
    
    if (json == null) return null;
    
    try {
      return DraftData.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      // Invalid JSON, clear it
      await clearDraft(userId: userId, communityId: communityId, type: type);
      return null;
    }
  }
  
  /// Check if draft exists
  Future<bool> hasDraft({
    required String userId,
    required String communityId,
    required PostType type,
  }) async {
    final draft = await getDraft(
      userId: userId,
      communityId: communityId,
      type: type,
    );
    return draft != null && draft.hasContent;
  }
  
  /// Clear draft after publishing
  Future<void> clearDraft({
    required String userId,
    required String communityId,
    required PostType type,
  }) async {
    final key = _buildKey(userId, communityId, type);
    await _prefs.remove(key);
  }
  
  /// Clear all drafts for a user (e.g., on logout)
  Future<void> clearAllDrafts(String userId) async {
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith('${_keyPrefix}_$userId'));
    
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
  
  /// Get all drafts for a community (for preview)
  Future<List<DraftData>> getCommunityDrafts({
    required String userId,
    required String communityId,
  }) async {
    final drafts = <DraftData>[];
    
    for (final type in PostType.values) {
      final draft = await getDraft(
        userId: userId,
        communityId: communityId,
        type: type,
      );
      if (draft != null && draft.hasContent) {
        drafts.add(draft);
      }
    }
    
    return drafts;
  }
}
