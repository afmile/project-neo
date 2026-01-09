/// Project Neo - Content Remote Datasource
///
/// Supabase API calls for content operations with optimistic updates.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

/// Abstract datasource for content operations
abstract class ContentRemoteDataSource {
  /// Get feed with type filter (LEGACY OFFSET)
  Future<List<PostModel>> getFeed({
    required String communityId,
    PostType? typeFilter,
    int limit = 20,
    int offset = 0,
  });
  
  /// Get feed with cursor-based pagination  
  Future<List<PostModel>> getFeedPaginated({
    required String communityId,
    PostType? typeFilter,
    required int limit,
    bool? cursorIsPinned,     // NEW: 3-field cursor
    String? cursorCreatedAt,
    String? cursorId,
  });
  
  /// Get single post by ID
  Future<PostModel> getPostById(String postId);
  
  /// Create new post
  Future<PostModel> createPost(PostModel post);
  
  /// Update post
  Future<PostModel> updatePost(PostModel post);
  
  /// Delete post
  Future<void> deletePost(String postId);
  
  /// Toggle reaction (returns new state: true=liked, false=unliked)
  Future<bool> toggleReaction({
    required String postId,
    String type = 'like',
  });
  
  /// Check if user reacted
  Future<bool> hasUserReacted(String postId);
  
  /// Get comments
  Future<List<CommentModel>> getComments({
    required String postId,
    int limit = 50,
    int offset = 0,
  });
  
  /// Add comment
  Future<CommentModel> addComment({
    required String postId,
    required String content,
    String? parentId,
  });
  
  /// Delete comment
  Future<void> deleteComment(String commentId);
  
  /// Vote on poll
  Future<void> votePoll({required String optionId});
  
  /// Get user's poll vote
  Future<String?> getUserPollVote(String postId);
  
  /// Create poll options
  Future<List<PollOption>> createPollOptions({
    required String postId,
    required List<String> options,
  });
}

/// Implementation using Supabase
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final SupabaseClient _client;
  
  ContentRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  
  String? get _currentUserId => _client.auth.currentUser?.id;
  
  @override
  Future<List<PostModel>> getFeed({
    required String communityId,
    PostType? typeFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Build query with type filter - use VIEW for local identity
      var query = _client
          .from('community_posts_view')
          .select('''
            *,
            poll_options (id, text, position, votes_count)
          ''')
          .eq('community_id', communityId);
      
      if (typeFilter != null) {
        query = query.eq('post_type', typeFilter.dbValue);
      }
      
      final response = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      // Get user reactions for these posts
      final postIds = (response as List).map((p) => p['id'] as String).toList();
      List<Map<String, dynamic>> userReactions = [];
      
      if (_currentUserId != null && postIds.isNotEmpty) {
        final reactionsResponse = await _client
            .from('post_reactions')
            .select('post_id, user_id')
            .eq('user_id', _currentUserId!)
            .inFilter('post_id', postIds);
        userReactions = List<Map<String, dynamic>>.from(reactionsResponse);
      }
      
      // Get user poll votes
      Map<String, String> userPollVotes = {};
      if (_currentUserId != null && postIds.isNotEmpty) {
        final pollPostIds = (response as List)
            .where((p) => p['post_type'] == 'poll')
            .map((p) => p['id'] as String)
            .toList();
        
        if (pollPostIds.isNotEmpty) {
          final votesResponse = await _client
              .from('poll_votes')
              .select('option_id, poll_options!inner(post_id)')
              .eq('user_id', _currentUserId!);
          
          for (final vote in votesResponse) {
            final postId = vote['poll_options']['post_id'] as String;
            userPollVotes[postId] = vote['option_id'] as String;
          }
        }
      }
      
      return (response as List).map((json) {
        final postId = json['id'] as String;
        return PostModel.fromJson(
          json as Map<String, dynamic>,
          currentUserId: _currentUserId,
          userReactions: userReactions,
          pollVote: userPollVotes.containsKey(postId) 
              ? {'option_id': userPollVotes[postId]} 
              : null,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<List<PostModel>> getFeedPaginated({
    required String communityId,
    PostType? typeFilter,
    required int limit,
    bool? cursorIsPinned,
    String? cursorCreatedAt,
    String? cursorId,
  }) async {
    try {
      // Build base query - use VIEW for local identity
      var query = _client
          .from('community_posts_view')
          .select('''
            *,
            poll_options (id, text, position, votes_count)
          ''')
          .eq('community_id', communityId);
      
      // Apply type filter
      if (typeFilter != null) {
        query = query.eq('post_type', typeFilter.dbValue);
      }
      
      // Apply 3-field cursor for pagination (is_pinned + created_at + id)
      // Respects ORDER BY is_pinned DESC, created_at DESC, id DESC
      if (cursorIsPinned != null && cursorCreatedAt != null && cursorId != null) {
        query = query.or(
          // Next group: pinned -> normal (true -> false)
          'is_pinned.lt.$cursorIsPinned,'
          // Same pinned status, older post
          'and(is_pinned.eq.$cursorIsPinned,created_at.lt.$cursorCreatedAt),'
          // Same pinned + same timestamp, smaller id
          'and(is_pinned.eq.$cursorIsPinned,created_at.eq.$cursorCreatedAt,id.lt.$cursorId)'
        );
      }
      
      // Ordering: MUST match cursor fields exactly
      final response = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit + 1); // +1 to detect hasMore
      
      // Get user reactions for these posts
      final postIds = (response as List)
          .take(limit) // Only process up to limit posts
          .map((p) => p['id'] as String)
          .toList();
      List<Map<String, dynamic>> userReactions = [];
      
      if (_currentUserId != null && postIds.isNotEmpty) {
        final reactionsResponse = await _client
            .from('post_reactions')
            .select('post_id, user_id')
            .eq('user_id', _currentUserId!)
            .inFilter('post_id', postIds);
        userReactions = List<Map<String, dynamic>>.from(reactionsResponse);
      }
      
      // Get user poll votes
      Map<String, String> userPollVotes = {};
      if (_currentUserId != null && postIds.isNotEmpty) {
        final pollPostIds = (response as List)
            .take(limit)
            .where((p) => p['post_type'] == 'poll')
            .map((p) => p['id'] as String)
            .toList();
        
        if (pollPostIds.isNotEmpty) {
          final votesResponse = await _client
              .from('poll_votes')
              .select('option_id, poll_options!inner(post_id)')
              .eq('user_id', _currentUserId!);
          
          for (final vote in votesResponse) {
            final postId = vote['poll_options']['post_id'] as String;
            userPollVotes[postId] = vote['option_id'] as String;
          }
        }
      }
      
      // Return up to 'limit' posts (the +1 is used by caller to detect hasMore)
      return (response as List).map((json) {
        final postId = json['id'] as String;
        return PostModel.fromJson(
          json as Map<String, dynamic>,
          currentUserId: _currentUserId,
          userReactions: userReactions,
          pollVote: userPollVotes.containsKey(postId) 
              ? {'option_id': userPollVotes[postId]} 
              : null,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<PostModel> getPostById(String postId) async {
    try {
      final response = await _client
          .from('community_posts_view')
          .select('''
            *,
            poll_options (id, text, position, votes_count)
          ''')
          .eq('id', postId)
          .single();
      
      // Check user reaction
      bool isLiked = false;
      if (_currentUserId != null) {
        final reaction = await _client
            .from('post_reactions')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', _currentUserId!)
            .maybeSingle();
        isLiked = reaction != null;
      }
      
      // Check poll vote if applicable
      Map<String, dynamic>? pollVote;
      if (response['post_type'] == 'poll' && _currentUserId != null) {
        final vote = await _client
            .from('poll_votes')
            .select('option_id')
            .eq('user_id', _currentUserId!)
            .inFilter('option_id', 
                (response['poll_options'] as List).map((o) => o['id']).toList())
            .maybeSingle();
        pollVote = vote;
      }
      
      return PostModel.fromJson(
        response,
        currentUserId: _currentUserId,
        userReactions: isLiked ? [{'post_id': postId, 'user_id': _currentUserId}] : [],
        pollVote: pollVote,
      );
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
          .from('community_blogs')
          .insert(post.toInsertJson())
          .select('''
            *,
            author:author_id (username, avatar_global_url)
          ''')
          .single();
      
      return PostModel.fromJson(response, currentUserId: _currentUserId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<PostModel> updatePost(PostModel post) async {
    try {
      final response = await _client
          .from('community_blogs')
          .update(post.toJson())
          .eq('id', post.id)
          .select('''
            *,
            author:author_id (username, avatar_global_url),
            poll_options (id, text, position, votes_count)
          ''')
          .single();
      
      return PostModel.fromJson(response, currentUserId: _currentUserId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<void> deletePost(String postId) async {
    try {
      await _client
          .from('community_blogs')
          .delete()
          .eq('id', postId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<bool> toggleReaction({
    required String postId,
    String type = 'like',
  }) async {
    try {
      if (_currentUserId == null) {
        throw const NeoAuthException('No autenticado');
      }
      
      // Check if reaction exists
      final existing = await _client
          .from('post_reactions')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', _currentUserId!)
          .maybeSingle();
      
      if (existing != null) {
        // Remove reaction
        await _client
            .from('post_reactions')
            .delete()
            .eq('id', existing['id']);
        return false;
      } else {
        // Add reaction
        await _client.from('post_reactions').insert({
          'post_id': postId,
          'user_id': _currentUserId,
          'type': type,
        });
        return true;
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      if (e is NeoAuthException) rethrow;
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<bool> hasUserReacted(String postId) async {
    try {
      if (_currentUserId == null) return false;
      
      final existing = await _client
          .from('post_reactions')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', _currentUserId!)
          .maybeSingle();
      
      return existing != null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<List<CommentModel>> getComments({
    required String postId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Get top-level comments first
      final response = await _client
          .from('post_comments')
          .select('''
            *,
            author:author_id (username, avatar_global_url)
          ''')
          .eq('post_id', postId)
          .isFilter('parent_id', null)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);
      
      final comments = (response as List)
          .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Get replies for each comment
      if (comments.isNotEmpty) {
        final parentIds = comments.map((c) => c.id).toList();
        final repliesResponse = await _client
            .from('post_comments')
            .select('''
              *,
              author:author_id (username, avatar_global_url)
            ''')
            .inFilter('parent_id', parentIds)
            .order('created_at', ascending: true);
        
        final repliesMap = <String, List<CommentEntity>>{};
        for (final replyJson in repliesResponse) {
          final reply = CommentModel.fromJson(replyJson as Map<String, dynamic>);
          final parentId = reply.parentId!;
          repliesMap.putIfAbsent(parentId, () => []).add(reply);
        }
        
        // Attach replies to their parents
        return comments.map((comment) {
          return CommentModel(
            id: comment.id,
            postId: comment.postId,
            authorId: comment.authorId,
            authorUsername: comment.authorUsername,
            authorAvatarUrl: comment.authorAvatarUrl,
            parentId: comment.parentId,
            content: comment.content,
            isEdited: comment.isEdited,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            replies: repliesMap[comment.id],
          );
        }).toList();
      }
      
      return comments;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<CommentModel> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      if (_currentUserId == null) {
        throw const NeoAuthException('No autenticado');
      }
      
      final response = await _client
          .from('post_comments')
          .insert({
            'post_id': postId,
            'author_id': _currentUserId,
            'parent_id': parentId,
            'content': content,
          })
          .select('''
            *,
            author:author_id (username, avatar_global_url)
          ''')
          .single();
      
      return CommentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      if (e is NeoAuthException) rethrow;
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await _client
          .from('post_comments')
          .delete()
          .eq('id', commentId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<void> votePoll({required String optionId}) async {
    try {
      if (_currentUserId == null) {
        throw const NeoAuthException('No autenticado');
      }
      
      // First, get the post_id to check if user already voted on this poll
      final optionData = await _client
          .from('poll_options')
          .select('post_id')
          .eq('id', optionId)
          .single();
      
      final postId = optionData['post_id'] as String;
      
      // Check for existing vote on this poll
      final existingVote = await _client
          .from('poll_votes')
          .select('id, option_id')
          .eq('user_id', _currentUserId!)
          .inFilter('option_id', (await _client
              .from('poll_options')
              .select('id')
              .eq('post_id', postId)).map((o) => o['id']).toList())
          .maybeSingle();
      
      if (existingVote != null) {
        // Remove old vote
        await _client
            .from('poll_votes')
            .delete()
            .eq('id', existingVote['id']);
        
        // If voting for same option, just remove (toggle off)
        if (existingVote['option_id'] == optionId) {
          return;
        }
      }
      
      // Add new vote
      await _client.from('poll_votes').insert({
        'option_id': optionId,
        'user_id': _currentUserId,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      if (e is NeoAuthException) rethrow;
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<String?> getUserPollVote(String postId) async {
    try {
      if (_currentUserId == null) return null;
      
      final optionIds = await _client
          .from('poll_options')
          .select('id')
          .eq('post_id', postId);
      
      if ((optionIds as List).isEmpty) return null;
      
      final vote = await _client
          .from('poll_votes')
          .select('option_id')
          .eq('user_id', _currentUserId!)
          .inFilter('option_id', optionIds.map((o) => o['id']).toList())
          .maybeSingle();
      
      return vote?['option_id'] as String?;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<List<PollOption>> createPollOptions({
    required String postId,
    required List<String> options,
  }) async {
    try {
      final optionsData = options.asMap().entries.map((e) => {
        'post_id': postId,
        'text': e.value,
        'position': e.key,
      }).toList();
      
      final response = await _client
          .from('poll_options')
          .insert(optionsData)
          .select();
      
      return (response as List)
          .map((json) => PollOption.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
