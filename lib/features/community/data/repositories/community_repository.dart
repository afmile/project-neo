/// Project Neo - Community Repository
///
/// Interface and implementation for community CRUD operations with Supabase.
library;

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/community_entity.dart';

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
      
      // Get communities where user is owner or member
      final response = await _supabase
          .from('communities')
          .select('''
            *,
            memberships!inner(user_id, role)
          ''')
          .eq('memberships.user_id', userId)
          .order('created_at', ascending: false);
      
      final communities = (response as List)
          .map((json) => _communityFromJson(json))
          .toList();
      
      return Right(communities);
    } catch (e) {
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
  Future<Either<Failure, CommunityEntity>> getCommunityBySlug(String slug) async {
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
      await _supabase.from('memberships').insert({
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
          .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
      
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
      
      await _supabase.from('memberships').insert({
        'user_id': userId,
        'community_id': communityId,
        'role': 'member',
      });
      
      // Increment member count
      await _supabase.rpc('increment_member_count', params: {
        'community_id_param': communityId,
      });
      
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
      
      await _supabase
          .from('memberships')
          .delete()
          .eq('user_id', userId)
          .eq('community_id', communityId);
      
      // Decrement member count
      await _supabase.rpc('decrement_member_count', params: {
        'community_id_param': communityId,
      });
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error saliendo de comunidad: $e'));
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
          ? CommunityTheme.fromJson(json['theme_config'] as Map<String, dynamic>)
          : const CommunityTheme(),
      isNsfw: json['is_nsfw_flag'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      memberCount: json['member_count'] as int? ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
      inviteOnly: json['invite_only'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['created_at'] as String),
    );
  }
  
  CommunityStatus _parseStatus(String? status) {
    switch (status) {
      case 'shadowbanned': return CommunityStatus.shadowbanned;
      case 'suspended': return CommunityStatus.suspended;
      case 'archived': return CommunityStatus.archived;
      default: return CommunityStatus.active;
    }
  }
}
