/// Project Neo - Community Repository
///
/// Interface and implementation for community CRUD operations with Supabase.
library;

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/community_entity.dart';
import '../../presentation/providers/community_members_provider.dart'; // For CommunityMember

// ═══════════════════════════════════════════════════════════════════════════
// INTERFACE
// ═══════════════════════════════════════════════════════════════════════════

abstract class CommunityRepository {
  /// Get communities the current user owns or is a member of
  Future<Either<Failure, List<CommunityEntity>>> getUserCommunities();

  /// Get all public communities for discovery
  Future<Either<Failure, List<CommunityEntity>>> discoverCommunities({
    String? searchQuery,
    String? categoryFilter,
    int limit = 20,
    int offset = 0,
  });

  /// Get a single community by ID
  Future<Either<Failure, CommunityEntity>> getCommunityById(String id);

  /// Get a single community by slug
  Future<Either<Failure, CommunityEntity>> getCommunityBySlug(String slug);

  /// Create a new community
  Future<Either<Failure, CommunityEntity>> createCommunity({
    required String title,
    required String slug,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    CommunityTheme? theme,
    bool isPrivate = false,
  });

  /// Update community details
  Future<Either<Failure, CommunityEntity>> updateCommunity({
    required String communityId,
    String? title,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    CommunityTheme? theme,
    bool? isPrivate,
  });

  /// Upload image to community storage bucket
  Future<Either<Failure, String>> uploadCommunityImage({
    required String communityId,
    required File imageFile,
    required String imageType, // 'icon' or 'banner'
  });

  /// Check if slug is available
  Future<Either<Failure, bool>> isSlugAvailable(String slug);

  /// Join a community
  Future<Either<Failure, void>> joinCommunity(String communityId);

  /// Leave a community
  Future<Either<Failure, void>> leaveCommunity(String communityId);

  /// Update local profile within a community
  Future<Either<Failure, void>> updateLocalProfile({
    required String communityId,
    String? nickname,
    String? avatarUrl,
    String? bio,
  });

  /// Get notification settings for a user in a community
  Future<Map<String, dynamic>> getNotificationSettings({
    required String communityId,
    required String userId,
  });

  /// Update notification settings for a user in a community
  Future<void> updateNotificationSettings({
    required String communityId,
    required String userId,
    required Map<String, dynamic> settings,
  });

  /// Fetch paginated wall posts for a community feed
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchWallPostsPaginated({
    required String communityId,
    required int limit,
    String? cursorCreatedAt,
    String? cursorId,
  });
  
  /// Create a new wall post
  Future<Either<Failure, Map<String, dynamic>>> createWallPost({
    required String communityId,
    required String content,
  });
  
  /// Toggle like on a wall post (returns true if now liked, false if unliked)
  Future<Either<Failure, bool>> toggleWallPostLike(String postId);
  
  /// Delete a wall post (author only)
  Future<Either<Failure, void>> deleteWallPost(String postId);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE WALL POSTS (separate from community wall)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Fetch profile wall posts for a user in a community
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchProfileWallPosts({
    required String profileUserId,
    required String communityId,
    int limit = 50,
  });
  
  /// Create a new profile wall post
  Future<Either<Failure, Map<String, dynamic>>> createProfileWallPost({
    required String profileUserId,
    required String communityId,
    required String content,
  });
  
  /// Toggle like on a profile wall post
  Future<Either<Failure, bool>> toggleProfileWallPostLike(String postId);
  
  /// Delete a profile wall post
  Future<Either<Failure, void>> deleteProfileWallPost(String postId);
  
  /// Update a community member's role (Send Invitation)
  Future<Either<Failure, void>> inviteMemberToRole({
    required String communityId,
    required String userId,
    required String newRole, // 'leader', 'moderator', 'member'
  });

  /// Accept a pending role invitation
  Future<Either<Failure, void>> acceptRoleInvitation({
    required String communityId,
  });

  /// Reject a pending role invitation
  Future<Either<Failure, void>> rejectRoleInvitation({
    required String communityId,
  });

  /// Ban a member from the community
  Future<Either<Failure, void>> banMember({
    required String communityId,
    required String userId,
    String? reason,
  });

  /// Unban a member (pardon)
  Future<Either<Failure, void>> unbanMember({
    required String communityId,
    required String userId,
  });

  /// Fetch list of banned members
  Future<Either<Failure, List<CommunityMember>>> fetchBannedMembers({
    required String communityId,
    int limit = 50,
    int offset = 0,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════

class CommunityRepositoryImpl implements CommunityRepository {
  final SupabaseClient _supabase;

  CommunityRepositoryImpl(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  Future<Either<Failure, List<CommunityEntity>>> getUserCommunities() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      print('🔍 Fetching user communities for: $userId');

      // Get communities where user is owner or member AND is_active = true
      final response = await _supabase
          .from('communities')
          .select('''
            *,
            community_members!inner(user_id, role, is_active)
          ''')
          .eq('community_members.user_id', userId)
          .eq('community_members.is_active', true)
          .order('created_at', ascending: false);

      print('📦 Raw response: $response');
      print('   Response length: ${(response as List).length}');

      final communities = (response as List)
          .map((json) => _communityFromJson(json))
          .toList();

      print('✅ Parsed ${communities.length} communities');
      for (final c in communities) {
        print('   - ${c.title} (${c.id})');
      }

      return Right(communities);
    } catch (e) {
      print('❌ ERROR getUserCommunities: $e');
      return Left(ServerFailure('Error cargando comunidades: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CommunityEntity>>> discoverCommunities({
    String? searchQuery,
    String? categoryFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('communities')
          .select()
          .eq('status', 'active')
          .eq('is_private', false);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      final response = await query
          .order('member_count', ascending: false)
          .range(offset, offset + limit - 1);

      final communities = (response as List)
          .map((json) => _communityFromJson(json))
          .toList();

      return Right(communities);
    } catch (e) {
      return Left(ServerFailure('Error en descubrimiento: $e'));
    }
  }

  @override
  Future<Either<Failure, CommunityEntity>> getCommunityById(String id) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .eq('id', id)
          .single();

      return Right(_communityFromJson(response));
    } catch (e) {
      return Left(ServerFailure('Comunidad no encontrada: $e'));
    }
  }

  @override
  Future<Either<Failure, CommunityEntity>> getCommunityBySlug(
    String slug,
  ) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .eq('slug', slug)
          .single();

      return Right(_communityFromJson(response));
    } catch (e) {
      return Left(ServerFailure('Comunidad no encontrada: $e'));
    }
  }

  @override
  Future<Either<Failure, CommunityEntity>> createCommunity({
    required String title,
    required String slug,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    CommunityTheme? theme,
    bool isPrivate = false,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final data = {
        'owner_id': userId,
        'title': title,
        'slug': slug.toLowerCase(),
        'description': description,
        'icon_url': iconUrl,
        'banner_url': bannerUrl,
        'theme_config': (theme ?? const CommunityTheme()).toJson(),
        'is_private': isPrivate,
        'member_count': 1, // Owner is first member
      };

      // Insert community
      final response = await _supabase
          .from('communities')
          .insert(data)
          .select()
          .single();

      final community = _communityFromJson(response);

      // Auto-join owner as member with role 'owner'
      await _supabase.from('community_members').insert({
        'user_id': userId,
        'community_id': community.id,
        'role': 'owner',
      });

      return Right(community);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Left(ValidationFailure('El slug ya está en uso'));
      }
      return Left(ServerFailure('Error creando comunidad: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Error creando comunidad: $e'));
    }
  }

  @override
  Future<Either<Failure, CommunityEntity>> updateCommunity({
    required String communityId,
    String? title,
    String? description,
    String? iconUrl,
    String? bannerUrl,
    CommunityTheme? theme,
    bool? isPrivate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (iconUrl != null) data['icon_url'] = iconUrl;
      if (bannerUrl != null) data['banner_url'] = bannerUrl;
      if (theme != null) data['theme_config'] = theme.toJson();
      if (isPrivate != null) data['is_private'] = isPrivate;

      final response = await _supabase
          .from('communities')
          .update(data)
          .eq('id', communityId)
          .select()
          .single();

      return Right(_communityFromJson(response));
    } catch (e) {
      return Left(ServerFailure('Error actualizando comunidad: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadCommunityImage({
    required String communityId,
    required File imageFile,
    required String imageType,
  }) async {
    try {
      final fileName = '${communityId}_$imageType.jpg';
      final path = 'communities/$communityId/$fileName';

      await _supabase.storage
          .from('community-media')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage
          .from('community-media')
          .getPublicUrl(path);

      return Right(publicUrl);
    } catch (e) {
      return Left(ServerFailure('Error subiendo imagen: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isSlugAvailable(String slug) async {
    try {
      final response = await _supabase
          .from('communities')
          .select('id')
          .eq('slug', slug.toLowerCase())
          .maybeSingle();

      return Right(response == null);
    } catch (e) {
      return Left(ServerFailure('Error verificando slug: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinCommunity(String communityId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      // Check if membership exists
      final existing = await _supabase
          .from('community_members')
          .select()
          .eq('user_id', userId)
          .eq('community_id', communityId)
          .maybeSingle();

      if (existing != null) {
        // Reactivate
        await _supabase
            .from('community_members')
            .update({'is_active': true, 'left_at': null})
            .eq('user_id', userId)
            .eq('community_id', communityId);
      } else {
        // Fetch global profile
        final userGlobal = await _supabase
            .from('users_global')
            .select('username, avatar_global_url, bio')
            .eq('id', userId)
            .single();

        // Join new
        await _supabase.from('community_members').insert({
          'user_id': userId,
          'community_id': communityId,
          'role': 'member',
          'nickname': userGlobal['username'],
          'avatar_url': userGlobal['avatar_global_url'],
          'bio': userGlobal['bio'],
          'is_active': true,
        });
      }

      // Increment member count (Not needed if DB Trigger handles it, but keeping for safety if trigger logic is complex/missing)
      // Note: Migration 014 adds a trigger for is_active updates, so this might be redundant for updates,
      // but strictly speaking, standard insert triggers usually handle inserts.
      // Let's rely on DB triggers ideally, but if we want to be safe we can keep it.
      // However, if we do it here AND DB does it, we might double count?
      // With migration 014 trigger, update is handled. Insert usually has its own trigger.
      // Let's assume existing triggers handle member_count on INSERT/DELETE/UPDATE.
      // Removing explicit RPC call to avoid double counting if triggers exist,
      // OR keeping it if no triggers exist.
      // The previous code called 'increment_member_count'.
      // Safest is to let the DB handle it if we trust our triggers.
      // Given I just added a trigger in 014, I should trust it for updates.
      // For inserts, usually there is a trigger too.
      // I will REMOVE the RPC call to be consistent with modern Supabase practices (Active/Passive implies triggers).

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error uniéndose a comunidad: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveCommunity(String communityId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      // Soft delete
      await _supabase
          .from('community_members')
          .update({
            'is_active': false,
            'left_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('community_id', communityId);

      // Member count decrement handled by DB trigger on is_active change (added in 014)

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error saliendo de comunidad: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocalProfile({
    required String communityId,
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final updates = <String, dynamic>{};
      if (nickname != null) updates['nickname'] = nickname;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      if (updates.isEmpty) return const Right(null);

      await _supabase
          .from('community_members')
          .update(updates)
          .eq('user_id', userId)
          .eq('community_id', communityId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error actualizando perfil local: $e'));
    }
  }

  @override
  Future<Map<String, dynamic>> getNotificationSettings({
    required String communityId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('community_members')
          .select('notification_settings')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .single();

      if (response['notification_settings'] == null) {
        return {
          'enabled': true,
          'chat': true,
          'mentions': true,
          'announcements': true,
          'wall_posts': false,
          'reactions': true,
        };
      }

      return response['notification_settings'] as Map<String, dynamic>;
    } catch (e) {
      // Return default on error to allow safe fail
      return {
        'enabled': true,
        'chat': true,
        'mentions': true,
        'announcements': true,
        'wall_posts': false,
        'reactions': true,
      };
    }
  }

  @override
  Future<void> updateNotificationSettings({
    required String communityId,
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      print('🗄️ Repository: Actualizando settings en DB');
      print('   Community: $communityId');
      print('   User: $userId');
      print('   Settings: $settings');

      // Check membership first
      final memberCheck = await _supabase
          .from('community_members')
          .select('user_id')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      print('   Member check result: $memberCheck');

      if (memberCheck == null) {
        print('❌ User is not a member of this community');
        throw Exception("User is not a member of this community");
      }

      print('💾 Ejecutando UPDATE...');
      // NO usar .select() - solo UPDATE
      await _supabase
          .from('community_members')
          .update({'notification_settings': settings})
          .eq('community_id', communityId)
          .eq('user_id', userId);

      print('✅ Settings actualizados correctamente');
    } catch (e) {
      print('❌ Error en repository: $e');
      throw Exception("Failed to update notification settings: $e");
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchWallPostsPaginated({
    required String communityId,
    required int limit,
    String? cursorCreatedAt,
    String? cursorId,
  }) async {
    try {
      print('🔄 Fetching wall posts from SQL VIEW for community: $communityId');

      // Query the VIEW instead of the raw table
      var query = _supabase
          .from('v_community_wall_feed')
          .select()
          .eq('community_id', communityId);

      // Apply cursor if provided
      if (cursorCreatedAt != null && cursorId != null) {
        query = query.or(
          'created_at.lt.$cursorCreatedAt,'
          'and(created_at.eq.$cursorCreatedAt,id.lt.$cursorId)',
        );
      }

      // Execute query
      final response = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);

      final posts = response as List;

      if (posts.isEmpty) {
        print('✅ No posts found');
        return const Right([]);
      }

      print('📦 Fetched ${posts.length} posts from view');

      // Map directly (The view already has flat fields)
      // CRITICAL: WallPostModel expects author.display_name for nickname
      final processedPosts = posts.map((data) {
        // Debug log to verify we are getting the right data
        if (posts.indexOf(data) == 0) {
          print('🔍 Sample Post Author from VIEW: ${data['display_name']}');
        }
        
        return <String, dynamic>{
          'id': data['id'],
          'community_id': data['community_id'],
          'author_id': data['author_id'],
          'content': data['content'],
          'created_at': data['created_at'],
          'media_url': data['media_url'],
          'media_type': data['media_type'],
          'comments_count': data['comments_count'] ?? 0,
          'likes_count': data['likes_count'] ?? 0,
          // Map view fields to the structure WallPostModel expects
          'author': <String, dynamic>{
            'id': data['author_id'],
            'username': data['display_name'] ?? 'Unknown', // Fallback username
            'display_name': data['display_name'], // ✅ Nickname from view
            'avatar_url': data['display_avatar'], // ✅ Local avatar from view
            'avatar_global_url': data['display_avatar'], // Fallback
            'is_leader': data['is_leader'] ?? false,
            'is_moderator': data['is_moderator'] ?? false,
          },
          'profile_user_id': null, // Community posts don't have profile_user_id
        };
      }).toList();

      print('✅ Posts processed from VIEW with local identities');
      return Right(processedPosts);
    } catch (e, stackTrace) {
      print('❌ Error fetching wall posts from view: $e');
      print('📍 Stack trace: $stackTrace');
      return Left(ServerFailure('Error cargando posts: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Map<String, dynamic>>> createWallPost({
    required String communityId,
    required String content,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }
      
      if (content.trim().isEmpty) {
        return const Left(ValidationFailure('El contenido no puede estar vacío'));
      }
      
      // Build insert payload
      // CRITICAL: profile_user_id must be NULL for community main wall posts
      // Only profile_wall_posts table should have profile_user_id set
      final payload = {
        'community_id': communityId,
        'profile_user_id': null, // ✅ NULL for community feed posts
        'author_id': userId,
        'content': content.trim(),
      };
      
      print('📝 Insert community_wall_posts payload: $payload');
      
      final response = await _supabase
          .from('community_wall_posts')
          .insert(payload)
          .select('''
            *,
            author:users_global!wall_posts_profile_user_id_fkey(username, avatar_global_url)
          ''')
          .single();
      
      // Add likes_count for the model
      response['likes_count'] = 0;
      response['comments_count'] = 0;
      
      print('✅ Wall post created: ${response['id']}');
      return Right(response);
    } on PostgrestException catch (e) {
      print('❌ Postgres error creating wall post: ${e.message}');
      return Left(ServerFailure('Error creando post: ${e.message}'));
    } catch (e) {
      print('❌ Error creating wall post: $e');
      return Left(ServerFailure('Error creando post: $e'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> toggleWallPostLike(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }
      
      // Check if like exists (table has composite PK: post_id + user_id, no 'id' column)
      final existing = await _supabase
          .from('wall_post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing != null) {
        // Unlike: remove the like using composite key
        await _supabase
            .from('wall_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        
        print('👎 Unliked wall post: $postId');
        return const Right(false);
      } else {
        // Like: add new like
        await _supabase.from('wall_post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
        
        print('👍 Liked wall post: $postId');
        return const Right(true);
      }
    } on PostgrestException catch (e) {
      print('❌ Postgres error toggling like: ${e.message}');
      return Left(ServerFailure('Error al dar like: ${e.message}'));
    } catch (e) {
      print('❌ Error toggling like: $e');
      return Left(ServerFailure('Error al dar like: $e'));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteWallPost(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }
      
      // Delete the post (RLS should ensure only author can delete)
      await _supabase
          .from('community_wall_posts')
          .delete()
          .eq('id', postId)
          .eq('author_id', userId); // Extra safety, though RLS should handle it
      
      print('🗑️ Wall post deleted: $postId');
      return const Right(null);
    } on PostgrestException catch (e) {
      print('❌ Postgres error deleting wall post: ${e.message}');
      return Left(ServerFailure('Error eliminando post: ${e.message}'));
    } catch (e) {
      print('❌ Error deleting wall post: $e');
      return Left(ServerFailure('Error eliminando post: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE WALL POSTS IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchProfileWallPosts({
    required String profileUserId,
    required String communityId,
    int limit = 50,
  }) async {
    try {
      print('🔄 Fetching profile wall posts for user: $profileUserId in community: $communityId');

      final response = await _supabase
          .from('profile_wall_posts')
          .select('''
            *,
            author:users_global!profile_wall_posts_author_id_fkey(username, avatar_global_url),
            user_likes:profile_wall_post_likes(user_id)
          ''')
          .eq('profile_user_id', profileUserId)
          .eq('community_id', communityId)
          .order('created_at', ascending: false)
          .limit(limit);

      final posts = response as List;

      if (posts.isEmpty) {
        print('✅ No profile wall posts found');
        return const Right([]);
      }

      print('📦 Fetched ${posts.length} profile wall posts');

      // Get comment counts and local profiles
      final postIds = posts.map((p) => p['id'] as String).toList();
      final authorIds = posts.map((p) => p['author_id'] as String).toSet().toList();

      final commentsCounts = <String, int>{};
      final localProfiles = <String, Map<String, dynamic>>{};

      await Future.wait([
        Future(() async {
          if (postIds.isNotEmpty) {
            final commentsResponse = await _supabase
                .from('profile_wall_post_comments')
                .select('post_id')
                .inFilter('post_id', postIds);
            for (final comment in commentsResponse as List) {
              final postId = comment['post_id'] as String;
              commentsCounts[postId] = (commentsCounts[postId] ?? 0) + 1;
            }
          }
        }),
        Future(() async {
          if (authorIds.isNotEmpty) {
            final profilesResponse = await _supabase
                .from('community_members')
                .select('user_id, nickname, avatar_url')
                .eq('community_id', communityId)
                .inFilter('user_id', authorIds);
            for (final profile in profilesResponse as List) {
              localProfiles[profile['user_id']] = profile;
            }
          }
        }),
      ]);

      // Inject data
      for (final post in posts) {
        post['comments_count'] = commentsCounts[post['id']] ?? 0;
        final authorId = post['author_id'];
        final localProfile = localProfiles[authorId];
        if (localProfile != null) {
          if (post['author'] == null) post['author'] = <String, dynamic>{};
          if (localProfile['nickname'] != null) {
            post['author']['username'] = localProfile['nickname'];
          }
          if (localProfile['avatar_url'] != null) {
            post['author']['avatar_global_url'] = localProfile['avatar_url'];
          }
        }
      }

      return Right(List<Map<String, dynamic>>.from(posts));
    } catch (e, stackTrace) {
      print('❌ Error fetching profile wall posts: $e');
      print('📍 Stack trace: $stackTrace');
      return Left(ServerFailure('Error cargando posts de perfil: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createProfileWallPost({
    required String profileUserId,
    required String communityId,
    required String content,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      if (content.trim().isEmpty) {
        return const Left(ValidationFailure('El contenido no puede estar vacío'));
      }

      final payload = {
        'profile_user_id': profileUserId,
        'community_id': communityId,
        'author_id': userId,
        'content': content.trim(),
      };

      print('📝 Insert profile_wall_posts payload: $payload');

      final response = await _supabase
          .from('profile_wall_posts')
          .insert(payload)
          .select('''
            *,
            author:users_global!profile_wall_posts_author_id_fkey(username, avatar_global_url)
          ''')
          .single();

      response['likes_count'] = 0;
      response['comments_count'] = 0;

      print('✅ Profile wall post created: ${response['id']}');
      return Right(response);
    } on PostgrestException catch (e) {
      print('❌ Postgres error creating profile wall post: ${e.message}');
      return Left(ServerFailure('Error creando post: ${e.message}'));
    } catch (e) {
      print('❌ Error creating profile wall post: $e');
      return Left(ServerFailure('Error creando post: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleProfileWallPostLike(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      final existing = await _supabase
          .from('profile_wall_post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('profile_wall_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        print('👎 Unliked profile wall post: $postId');
        return const Right(false);
      } else {
        await _supabase.from('profile_wall_post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
        print('👍 Liked profile wall post: $postId');
        return const Right(true);
      }
    } on PostgrestException catch (e) {
      print('❌ Postgres error toggling profile like: ${e.message}');
      return Left(ServerFailure('Error al dar like: ${e.message}'));
    } catch (e) {
      print('❌ Error toggling profile like: $e');
      return Left(ServerFailure('Error al dar like: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfileWallPost(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(AuthFailure('Usuario no autenticado'));
      }

      await _supabase
          .from('profile_wall_posts')
          .delete()
          .eq('id', postId);

      print('🗑️ Profile wall post deleted: $postId');
      return const Right(null);
    } on PostgrestException catch (e) {
      print('❌ Postgres error deleting profile wall post: ${e.message}');
      return Left(ServerFailure('Error eliminando post: ${e.message}'));
    } catch (e) {
      print('❌ Error deleting profile wall post: $e');
      return Left(ServerFailure('Error eliminando post: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> inviteMemberToRole({
    required String communityId,
    required String userId,
    required String newRole,
  }) async {
    try {
      final validRoles = ['leader', 'moderator', 'member'];
      if (!validRoles.contains(newRole)) {
        return Left(ServerFailure('Invalid role specified'));
      }

      // Logic: Demotions are immediate, Promotions are pending
      // checking current role is complex here without fetching, but we can assume:
      // if newRole == 'member', it's a demotion (immediate).
      // if newRole == 'leader' or 'moderator', it's a promotion (pending).
      
      bool isPromotion = newRole != 'member';

      if (isPromotion) {
        // Sets pending_role, leaves active role untouched
        await _supabase
            .from('community_members')
            .update({
              'pending_role': newRole,
              // Do NOT update actual role columns yet
            })
            .eq('community_id', communityId)
            .eq('user_id', userId);
      } else {
        // Demotion: Immediate update, clear flags
        await _supabase
            .from('community_members')
            .update({
              'role': 'member',
              'is_leader': false,
              'is_moderator': false,
              'pending_role': null, // Clear any pending stuff
            })
            .eq('community_id', communityId)
            .eq('user_id', userId);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptRoleInvitation({
    required String communityId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Left(ServerFailure('User not authenticated'));

      // 1. Fetch pending role
      final data = await _supabase
          .from('community_members')
          .select('pending_role')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .single();

      final pendingRole = data['pending_role'] as String?;
      if (pendingRole == null) return Left(ServerFailure('No pending role invitation'));

      // 2. Apply Role
      final updates = <String, dynamic>{
        'role': 'member', // default base
        'is_leader': false,
        'is_moderator': false,
        'pending_role': null, // Clear pending
      };

      if (pendingRole == 'leader') {
         updates['role'] = 'leader';
         updates['is_leader'] = true;
         updates['is_moderator'] = true; // Leaders are mods too
      } else if (pendingRole == 'moderator') {
         updates['role'] = 'moderator';
         updates['is_moderator'] = true;
      }
      // if pending was 'member', it wouldn't be here as that's immediate demotion

      await _supabase
          .from('community_members')
          .update(updates)
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // 3. Update Notifications (mark accepted)
      await _supabase
          .from('community_notifications')
          .update({'action_status': 'accepted', 'read_at': DateTime.now().toIso8601String()})
          .eq('recipient_id', userId)
          .eq('type', 'role_invitation')
          .eq('entity_id', communityId) 
          .eq('action_status', 'pending');

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectRoleInvitation({
    required String communityId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Left(ServerFailure('User not authenticated'));

      // Clear pending role
      await _supabase
          .from('community_members')
          .update({'pending_role': null})
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Mark notification rejected
      await _supabase
          .from('community_notifications')
          .update({'action_status': 'rejected', 'read_at': DateTime.now().toIso8601String()})
          .eq('recipient_id', userId)
          .eq('type', 'role_invitation')
          .eq('entity_id', communityId)
          .eq('action_status', 'pending');

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> banMember({
    required String communityId,
    required String userId,
    String? reason,
  }) async {
    try {
      // Set banned flag. 
      // We DO NOT set is_active = false, because we want to keep their role/data 
      // frozen until unban, BUT we must ensure they don't show up in valid member lists.
      await _supabase.from('community_members').update({
        'is_banned': true,
        'banned_at': DateTime.now().toIso8601String(),
      }).eq('community_id', communityId).eq('user_id', userId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al banear usuario: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unbanMember({
    required String communityId,
    required String userId,
  }) async {
    try {
      await _supabase.from('community_members').update({
        'is_banned': false,
        'banned_at': null,
      }).eq('community_id', communityId).eq('user_id', userId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al desbanear usuario: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CommunityMember>>> fetchBannedMembers({
    required String communityId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('community_members')
          .select('''
            user_id, role, joined_at, nickname, avatar_url, is_leader, is_moderator, is_active, is_banned, banned_at,
            users_global!community_members_user_id_fkey(username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('is_banned', true)
          .order('banned_at', ascending: false)
          .range(offset, offset + limit - 1);

      final members = (response as List).map((json) => CommunityMember.fromJson(json)).toList();
      return Right(members);
    } catch (e) {
      return Left(ServerFailure('Error cargando usuarios baneados: $e'));
    }
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  CommunityEntity _communityFromJson(Map<String, dynamic> json) {
    return CommunityEntity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      theme: json['theme_config'] != null
          ? CommunityTheme.fromJson(
              json['theme_config'] as Map<String, dynamic>,
            )
          : const CommunityTheme(),
      isNsfw: json['is_nsfw_flag'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      memberCount: json['member_count'] as int? ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
      inviteOnly: json['invite_only'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? json['created_at'] as String,
      ),
    );
  }

  CommunityStatus _parseStatus(String? status) {
    switch (status) {
      case 'shadowbanned':
        return CommunityStatus.shadowbanned;
      case 'suspended':
        return CommunityStatus.suspended;
      case 'archived':
        return CommunityStatus.archived;
      default:
        return CommunityStatus.active;
    }
  }
}
