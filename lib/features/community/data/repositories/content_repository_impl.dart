/// Project Neo - Content Repository Implementation
///
/// Implements ContentRepository using remote datasource.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_remote_datasource.dart';
import '../models/post_model.dart';

/// Content repository implementation
class ContentRepositoryImpl implements ContentRepository {
  final ContentRemoteDataSource remoteDataSource;
  
  ContentRepositoryImpl({required this.remoteDataSource});
  
  @override
  Future<Either<Failure, List<PostEntity>>> getFeed({
    required String communityId,
    PostType? typeFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final posts = await remoteDataSource.getFeed(
        communityId: communityId,
        typeFilter: typeFilter,
        limit: limit,
        offset: offset,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<PostEntity>>> getFeedPaginated({
    required String communityId,
    PostType? typeFilter,
    required int limit,
    bool? cursorIsPinned,
    String? cursorCreatedAt,
    String? cursorId,
  }) async {
    try {
      final posts = await remoteDataSource.getFeedPaginated(
        communityId: communityId,
        typeFilter: typeFilter,
        limit: limit,
        cursorIsPinned: cursorIsPinned,
        cursorCreatedAt: cursorCreatedAt,
        cursorId: cursorId,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, PostEntity>> getPostById(String postId) async {
    try {
      final post = await remoteDataSource.getPostById(postId);
      return Right(post);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, PostEntity>> createPost(PostEntity post) async {
    try {
      final postModel = PostModel(
        id: post.id,
        communityId: post.communityId,
        authorId: post.authorId,
        authorUsername: post.authorUsername,
        authorAvatarUrl: post.authorAvatarUrl,
        postType: post.postType,
        title: post.title,
        content: post.content,
        richContent: post.richContent,
        coverImageUrl: post.coverImageUrl,
        isPinned: post.isPinned,
        pinSize: post.pinSize,
        mediaUrls: post.mediaUrls,
        reactionsCount: 0,
        commentsCount: 0,
        isLikedByCurrentUser: false,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
      );
      
      final created = await remoteDataSource.createPost(postModel);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, PostEntity>> updatePost(PostEntity post) async {
    try {
      final postModel = PostModel(
        id: post.id,
        communityId: post.communityId,
        authorId: post.authorId,
        postType: post.postType,
        title: post.title,
        content: post.content,
        richContent: post.richContent,
        coverImageUrl: post.coverImageUrl,
        isPinned: post.isPinned,
        pinSize: post.pinSize,
        mediaUrls: post.mediaUrls,
        reactionsCount: post.reactionsCount,
        commentsCount: post.commentsCount,
        isLikedByCurrentUser: post.isLikedByCurrentUser,
        createdAt: post.createdAt,
        updatedAt: DateTime.now(),
      );
      
      final updated = await remoteDataSource.updatePost(postModel);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> toggleReaction({
    required String postId,
    String type = 'like',
  }) async {
    try {
      final newState = await remoteDataSource.toggleReaction(
        postId: postId,
        type: type,
      );
      return Right(newState);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, bool>> hasUserReacted(String postId) async {
    try {
      final hasReacted = await remoteDataSource.hasUserReacted(postId);
      return Right(hasReacted);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<CommentEntity>>> getComments({
    required String postId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final comments = await remoteDataSource.getComments(
        postId: postId,
        limit: limit,
        offset: offset,
      );
      return Right(comments);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      final comment = await remoteDataSource.addComment(
        postId: postId,
        content: content,
        parentId: parentId,
      );
      return Right(comment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteComment(String commentId) async {
    try {
      await remoteDataSource.deleteComment(commentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> votePoll({required String optionId}) async {
    try {
      await remoteDataSource.votePoll(optionId: optionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, String?>> getUserPollVote(String postId) async {
    try {
      final vote = await remoteDataSource.getUserPollVote(postId);
      return Right(vote);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<PollOption>>> createPollOptions({
    required String postId,
    required List<String> options,
  }) async {
    try {
      final pollOptions = await remoteDataSource.createPollOptions(
        postId: postId,
        options: options,
      );
      return Right(pollOptions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
