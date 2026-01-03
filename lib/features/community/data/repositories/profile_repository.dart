import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/wall_post.dart';
import '../../data/models/wall_post_model.dart';

abstract class ProfileRepository {
  Future<List<WallPost>> getProfilePosts(String userId, String communityId);
  Future<void> createPost(String userId, String communityId, String content);
  Future<void> deletePost(String postId);
  Future<void> toggleLike(String postId);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _client;

  ProfileRepositoryImpl(this._client);

  @override
  Future<List<WallPost>> getProfilePosts(String userId, String communityId) async {
    final response = await _client
        .from('profile_wall_posts')
        .select('''
          *,
          author:users_global!profile_wall_posts_author_id_fkey(username, avatar_global_url),
          user_likes:profile_wall_post_likes(user_id)
        ''')
        .eq('profile_user_id', userId)
        .eq('community_id', communityId)
        .order('created_at', ascending: false);

    // Aquí deberíamos enriquecer con datos locales de comunidad si es necesario
    // Por ahora devolvemos el modelo base
    return WallPostModel.listFromSupabase(
      response as List,
      _client.auth.currentUser?.id,
    );
  }

  @override
  Future<void> createPost(String userId, String communityId, String content) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('No autenticado');

    await _client.from('profile_wall_posts').insert({
      'profile_user_id': userId,
      'community_id': communityId,
      'author_id': currentUser.id,
      'content': content.trim(),
    });
  }

  @override
  Future<void> deletePost(String postId) async {
    await _client.from('profile_wall_posts').delete().eq('id', postId);
  }

  @override
  Future<void> toggleLike(String postId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('No autenticado');

    // Verificar si ya dio like
    final existing = await _client
        .from('profile_wall_post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', currentUser.id)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _client
          .from('profile_wall_post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUser.id);
    } else {
      // Like
      await _client
          .from('profile_wall_post_likes')
          .insert({
            'post_id': postId,
            'user_id': currentUser.id,
          });
    }
  }
}
