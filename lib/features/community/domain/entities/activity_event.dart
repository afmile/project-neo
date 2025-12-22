/// Project Neo - Activity Event
///
/// Represents an activity event from a friend's timeline
library;

import 'package:equatable/equatable.dart';

/// Types of activity events
enum ActivityType {
  /// Published a new blog post
  newBlog,
  
  /// Commented on content
  newComment,
  
  /// Leveled up
  levelUp,
  
  /// Created a new quiz
  newQuiz,
  
  /// Joined the community
  joinedCommunity,
  
  /// Created a wiki page
  newWiki,
  
  /// Completed a quiz
  completedQuiz,
}

extension ActivityTypeExtension on ActivityType {
  /// Get description template for this activity
  String get description {
    switch (this) {
      case ActivityType.newBlog:
        return 'publicó un nuevo blog';
      case ActivityType.newComment:
        return 'comentó en';
      case ActivityType.levelUp:
        return 'subió de nivel a';
      case ActivityType.newQuiz:
        return 'creó un quiz';
      case ActivityType.joinedCommunity:
        return 'se unió a la comunidad';
      case ActivityType.newWiki:
        return 'creó una wiki';
      case ActivityType.completedQuiz:
        return 'completó el quiz';
    }
  }
  
  /// Get icon for this activity type
  String get emoji {
    switch (this) {
      case ActivityType.newBlog:
        return '📝';
      case ActivityType.newComment:
        return '💬';
      case ActivityType.levelUp:
        return '⬆️';
      case ActivityType.newQuiz:
        return '❓';
      case ActivityType.joinedCommunity:
        return '👋';
      case ActivityType.newWiki:
        return '📘';
      case ActivityType.completedQuiz:
        return '✅';
    }
  }
}

/// Represents an activity event in the timeline
class ActivityEvent extends Equatable {
  /// Unique event ID
  final String id;
  
  /// User who performed the activity
  final String userId;
  
  /// Username
  final String username;
  
  /// Avatar URL (optional)
  final String? avatarUrl;
  
  /// Type of activity
  final ActivityType type;
  
  /// Title/main content (e.g., blog title, level number)
  final String title;
  
  /// Additional subtitle/context
  final String? subtitle;
  
  /// When the event occurred
  final DateTime timestamp;

  const ActivityEvent({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.type,
    required this.title,
    this.subtitle,
    required this.timestamp,
  });

  /// Get full description of the event
  String get fullDescription {
    return '$username ${type.description}';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        username,
        avatarUrl,
        type,
        title,
        subtitle,
        timestamp,
      ];
}
