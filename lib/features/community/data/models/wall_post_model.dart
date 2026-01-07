/// Project Neo - Wall Post Model
///
/// Data model for converting Supabase wall_posts to WallPost entity
library;

import '../../domain/entities/wall_post.dart';
import '../../domain/entities/wall_post_comment.dart';

class WallPostModel {
  /// Convert from Supabase JSON to WallPost entity
  static WallPost fromSupabase(Map<String, dynamic> json, String? currentUserId) {
    // Extract author data from merged local/global profile
    final author = json['author'] as Map<String, dynamic>?;
    
    // Check if current user liked this post
    final userLikes = json['user_likes'] as List<dynamic>?;
    final isLikedByMe = currentUserId != null &&
        userLikes != null &&
        userLikes.any((like) => like['user_id'] == currentUserId);
    
    // Get comments array (supports both community and profile wall posts)
    final commentsList = (json['wall_post_comments'] as List?) ?? 
                        (json['profile_wall_post_comments'] as List?) ?? 
                        [];
    
    // Parse comments count - prefer explicit count, fallback to array length
    int commentsCount = 0;
    if (json['comments_count'] != null) {
      final commentsData = json['comments_count'];
      if (commentsData is List && commentsData.isNotEmpty) {
        commentsCount = commentsData[0]['count'] as int? ?? 0;
      } else if (commentsData is int) {
        commentsCount = commentsData;
      }
    } else {
      // Fallback: use full comments list length if aggregation not provided
      // Note: This is approximate since we only fetch 1 comment inline
      commentsCount = commentsList.length;
    }
    
    // Prioritize local identity: display_name (nickname) over username
    final displayName = author?['display_name'] as String?;
    final username = author?['username'] as String? ?? 'Usuario';
    
    // Prioritize local avatar over global avatar
    final localAvatar = author?['avatar_url'] as String?;
    final globalAvatar = author?['avatar_global_url'] as String?;
    
    return WallPost(
      id: json['id'] as String,
      communityId: json['community_id'] as String?,
      authorId: json['author_id'] as String,
      authorName: displayName ?? username,  // ✅ Prioritize nickname
      authorDisplayName: displayName,
      authorAvatar: localAvatar ?? globalAvatar,  // ✅ Prioritize local avatar
      content: json['content'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      likes: json['likes_count'] as int? ?? 0,
      isLikedByCurrentUser: isLikedByMe,
      commentsCount: commentsCount,
      firstComment: commentsList.isNotEmpty
          ? WallPostComment.fromSupabase(commentsList[0], currentUserId)
          : null,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
    );
  }

  /// Convert list from Supabase
  static List<WallPost> listFromSupabase(
    List<dynamic> jsonList,
    String? currentUserId,
  ) {
    return jsonList
        .map((json) => fromSupabase(json as Map<String, dynamic>, currentUserId))
        .toList();
  }
}
