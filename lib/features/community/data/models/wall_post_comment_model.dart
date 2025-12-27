/// Project Neo - Wall Post Comment Model
///
/// Data model for converting Supabase wall_post_comments to WallPostComment entity
library;

import '../../domain/entities/wall_post_comment.dart';

class WallPostCommentModel {
  /// Convert from Supabase JSON to WallPostComment entity
  static WallPostComment fromSupabase(Map<String, dynamic> json) {
    // Extract author data from joined users_global table
    final author = json['author'] as Map<String, dynamic>?;
    
    return WallPostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorName: author?['username'] as String? ?? 'Usuario',
      authorAvatar: author?['avatar_global_url'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert list from Supabase
  static List<WallPostComment> listFromSupabase(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromSupabase(json as Map<String, dynamic>))
        .toList();
  }
}
