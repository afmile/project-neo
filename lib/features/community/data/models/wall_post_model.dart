/// Project Neo - Wall Post Model
///
/// Data model for converting Supabase wall_posts to WallPost entity
library;

import '../../domain/entities/wall_post.dart';

class WallPostModel {
  /// Convert from Supabase JSON to WallPost entity
  static WallPost fromSupabase(Map<String, dynamic> json, String? currentUserId) {
    // Extract author data from joined users_global table
    final author = json['author'] as Map<String, dynamic>?;
    
    return WallPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: author?['username'] as String? ?? 'Usuario',
      authorAvatar: author?['avatar_global_url'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      likes: json['likes_count'] as int? ?? 0,
      isLikedByCurrentUser: false, // TODO: Check if current user liked this post
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
