/// Project Neo - Friend Presence
///
/// Represents a friend's online status and current location
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Where a friend is currently active
enum PresenceLocation {
  /// In a voice chat room
  voiceChat,
  
  /// Reading content (blog, wiki, etc.)
  reading,
  
  /// Taking a quiz
  quiz,
  
  /// Browsing/navigating
  browsing,
  
  /// Offline
  offline,
}

extension PresenceLocationExtension on PresenceLocation {
  /// Get icon for this location
  IconData get icon {
    switch (this) {
      case PresenceLocation.voiceChat:
        return Icons.mic;
      case PresenceLocation.reading:
        return Icons.menu_book;
      case PresenceLocation.quiz:
        return Icons.quiz;
      case PresenceLocation.browsing:
        return Icons.visibility;
      case PresenceLocation.offline:
        return Icons.circle_outlined;
    }
  }
  
  /// Get label for this location
  String get label {
    switch (this) {
      case PresenceLocation.voiceChat:
        return 'En Chat Voz';
      case PresenceLocation.reading:
        return 'Leyendo';
      case PresenceLocation.quiz:
        return 'En Quiz';
      case PresenceLocation.browsing:
        return 'Navegando';
      case PresenceLocation.offline:
        return 'Offline';
    }
  }
  
  /// Get emoji for this location
  String get emoji {
    switch (this) {
      case PresenceLocation.voiceChat:
        return '🎙️';
      case PresenceLocation.reading:
        return '📖';
      case PresenceLocation.quiz:
        return '🎮';
      case PresenceLocation.browsing:
        return '👀';
      case PresenceLocation.offline:
        return '⚫';
    }
  }
}

/// Represents a friend's current presence/status
class FriendPresence extends Equatable {
  /// User ID
  final String userId;
  
  /// Username
  final String username;
  
  /// Avatar URL (optional)
  final String? avatarUrl;
  
  /// Whether the user is online
  final bool isOnline;
  
  /// Current location/activity
  final PresenceLocation location;
  
  /// Additional detail about location (e.g., "Blog: Flutter Tips")
  final String? locationDetail;

  const FriendPresence({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.isOnline,
    required this.location,
    this.locationDetail,
  });

  @override
  List<Object?> get props => [
        userId,
        username,
        avatarUrl,
        isOnline,
        location,
        locationDetail,
      ];
}
