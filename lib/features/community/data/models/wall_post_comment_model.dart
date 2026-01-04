/// Project Neo - Wall Post Comment Model
///
/// Data model for converting Supabase wall_post_comments to WallPostComment entity
library;

import '../../domain/entities/wall_post_comment.dart';

class WallPostCommentModel {
  /// Convert from Supabase JSON to WallPostComment entity
  /// Supports local profile override (community_members) and likes data
  static WallPostComment fromSupabase(Map<String, dynamic> json, String? currentUserId) {
    // Extract author data from joined users_global table
    final author = json['author'] as Map<String, dynamic>?;
    
    // Extract local profile data if available (from community_members join)
    final localProfile = json['local_profile'] as Map<String, dynamic>?;
    
    // Determine display name: local nickname > global username > fallback
    String displayName = 'Usuario';
    if (localProfile != null && localProfile['nickname'] != null && 
        (localProfile['nickname'] as String).isNotEmpty) {
      displayName = localProfile['nickname'] as String;
    } else if (author != null && author['username'] != null) {
      displayName = author['username'] as String;
    }
    
    // Determine avatar: local avatar > global avatar
    String? displayAvatar;
    if (localProfile != null && localProfile['avatar_url'] != null &&
        (localProfile['avatar_url'] as String).isNotEmpty) {
      displayAvatar = localProfile['avatar_url'] as String;
    } else if (author != null) {
      displayAvatar = author['avatar_global_url'] as String?;
    }
    
    // Parse likes data
    final userLikes = json['user_likes'] as List<dynamic>? ?? [];
    final likesCount = json['likes_count'] as int? ?? userLikes.length;
    final isLiked = currentUserId != null && 
        userLikes.any((like) => like['user_id'] == currentUserId);
    
    return WallPostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorName: displayName,
      authorAvatar: displayAvatar,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: likesCount,
      isLikedByCurrentUser: isLiked,
    );
  }

  /// Convert list from Supabase
  static List<WallPostComment> listFromSupabase(List<dynamic> jsonList, String? currentUserId) {
    return jsonList
        .map((json) => fromSupabase(json as Map<String, dynamic>, currentUserId))
        .toList();
  }
}

