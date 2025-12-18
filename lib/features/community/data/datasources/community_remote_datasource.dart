/// Project Neo - Community Remote Datasource
///
/// Supabase API calls for communities.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/community_model.dart';
import '../models/post_model.dart';

/// Abstract datasource
abstract class CommunityRemoteDataSource {
  /// Get community by slug with tabs
  Future<CommunityModel> getCommunityBySlug(String slug);
  
  /// Get community posts (feed)
  Future<List<PostModel>> getCommunityPosts(String communityId, {int limit = 20, int offset = 0});
  
  /// Get pinned posts for Bento grid
  Future<List<PostModel>> getPinnedPosts(String communityId);
  
  /// Create new post
  Future<PostModel> createPost(PostModel post);
  
  /// Update community tabs order
  Future<void> updateTabsOrder(String communityId, List<CommunityTabModel> tabs);
  
  /// Join community
  Future<void> joinCommunity(String communityId);
  
  /// Leave community
  Future<void> leaveCommunity(String communityId);
}

/// Implementation using Supabase
class CommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final SupabaseClient _client;
  
  CommunityRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  
  @override
  Future<CommunityModel> getCommunityBySlug(String slug) async {
    try {
      final response = await _client
          .from('communities')
          .select('''
            *,
            community_tabs (*)
          ''')
          .eq('slug', slug)
          .single();
      
      return CommunityModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<List<PostModel>> getCommunityPosts(
    String communityId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('community_posts')
          .select('''
            *,
            author:author_id (username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<List<PostModel>> getPinnedPosts(String communityId) async {
    try {
      final response = await _client
          .from('community_posts')
          .select('''
            *,
            author:author_id (username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('is_pinned', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<PostModel> createPost(PostModel post) async {
    try {
      final response = await _client
          .from('community_posts')
          .insert(post.toInsertJson())
          .select('''
            *,
            author:author_id (username, avatar_global_url)
          ''')
          .single();
      
      return PostModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<void> updateTabsOrder(String communityId, List<CommunityTabModel> tabs) async {
    try {
      // Update each tab's sort_order
      for (var i = 0; i < tabs.length; i++) {
        await _client
            .from('community_tabs')
            .update({'sort_order': i})
            .eq('id', tabs[i].id);
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<void> joinCommunity(String communityId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const NeoAuthException('No autenticado');
      
      await _client.from('memberships').insert({
        'user_id': userId,
        'community_id': communityId,
        'role': 'member',
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Already a member
        return;
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<void> leaveCommunity(String communityId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const NeoAuthException('No autenticado');
      
      await _client
          .from('memberships')
          .delete()
          .eq('user_id', userId)
          .eq('community_id', communityId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
