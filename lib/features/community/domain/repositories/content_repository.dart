/// Project Neo - Content Repository
///
/// Unified repository for all content types (blogs, wikis, polls, quizzes).
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';

/// Content repository interface for polymorphic content management
abstract class ContentRepository {
  /// Get feed posts with optional type filter and pagination
  Future<Either<Failure, List<PostEntity>>> getFeed({
    required String communityId,
    PostType? typeFilter,
    int limit = 20,
    int offset = 0,
  });
  
  /// Get single post by ID with full details
  Future<Either<Failure, PostEntity>> getPostById(String postId);
  
  /// Create new post (blog, wiki, poll, quiz)
  Future<Either<Failure, PostEntity>> createPost(PostEntity post);
  
  /// Update existing post
  Future<Either<Failure, PostEntity>> updatePost(PostEntity post);
  
  /// Delete post
  Future<Either<Failure, void>> deletePost(String postId);
  
  /// Toggle reaction (like/unlike) with optimistic update support
  /// Returns the new liked state (true = liked, false = unliked)
  Future<Either<Failure, bool>> toggleReaction({
    required String postId,
    String type = 'like',
  });
  
  /// Check if user has reacted to a post
  Future<Either<Failure, bool>> hasUserReacted(String postId);
  
  /// Get comments for a post
  Future<Either<Failure, List<CommentEntity>>> getComments({
    required String postId,
    int limit = 50,
    int offset = 0,
  });
  
  /// Add comment to post
  Future<Either<Failure, CommentEntity>> addComment({
    required String postId,
    required String content,
    String? parentId,
  });
  
  /// Delete comment
  Future<Either<Failure, void>> deleteComment(String commentId);
  
  /// Vote on poll option
  /// Note: This is SEPARATE from liking - voting on a poll ≠ liking it
  Future<Either<Failure, void>> votePoll({
    required String optionId,
  });
  
  /// Get user's poll vote for a post
  Future<Either<Failure, String?>> getUserPollVote(String postId);
  
  /// Create poll options for a poll post
  Future<Either<Failure, List<PollOption>>> createPollOptions({
    required String postId,
    required List<String> options,
  });
}
