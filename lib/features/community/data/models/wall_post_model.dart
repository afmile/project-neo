/// Project Neo - Wall Post Model
///
/// Data model for converting Supabase wall_posts to WallPost entity
library;

import '../../domain/entities/wall_post.dart';
import '../../domain/entities/wall_post_comment.dart';

class WallPostModel {
  /// Convert from Supabase JSON to WallPost entity
  static WallPost fromSupabase(Map<String, dynamic> json, String? currentUserId) {
    // Extract author data from joined users_global table
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
    
    return WallPost(
      id: json['id'] as String,
      communityId: json['community_id'] as String?,
      authorId: json['author_id'] as String,  // ✅ CORRECTED: use author_id, not profile_user_id
      authorName: author?['username'] as String? ?? 'Usuario',
      authorDisplayName: author?['display_name'] as String?,
      authorAvatar: author?['avatar_global_url'] as String?,
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
