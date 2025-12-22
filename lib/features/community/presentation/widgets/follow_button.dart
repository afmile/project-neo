/// Project Neo - Follow Button
///
/// Smart button that displays different states based on friendship status
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/friendship_status.dart';

class FollowButton extends StatelessWidget {
  final FriendshipStatus status;
  final VoidCallback? onPressed;

  const FollowButton({
    super.key,
    required this.status,
    this.onPressed,
  });

  Color _getBackgroundColor() {
    switch (status) {
      case FriendshipStatus.notFollowing:
        return NeoColors.accent;
      case FriendshipStatus.followingThem:
        return NeoColors.card;
      case FriendshipStatus.friends:
        return const Color(0xFF10B981); // Green for friends
    }
  }

  Color _getTextColor() {
    switch (status) {
      case FriendshipStatus.notFollowing:
        return Colors.white;
      case FriendshipStatus.followingThem:
        return Colors.white70;
      case FriendshipStatus.friends:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case FriendshipStatus.notFollowing:
        return NeoColors.accent;
      case FriendshipStatus.followingThem:
        return Colors.white.withValues(alpha: 0.3);
      case FriendshipStatus.friends:
        return const Color(0xFF10B981);
    }
  }

  IconData? _getIcon() {
    switch (status) {
      case FriendshipStatus.notFollowing:
        return Icons.person_add;
      case FriendshipStatus.followingThem:
        return Icons.check;
      case FriendshipStatus.friends:
        return Icons.people;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        _getIcon(),
        size: 18,
        color: _getTextColor(),
      ),
      label: Text(
        status.buttonText,
        style: TextStyle(
          color: _getTextColor(),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(),
        foregroundColor: _getTextColor(),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        elevation: status == FriendshipStatus.friends ? 4 : 0,
        shadowColor: status == FriendshipStatus.friends
            ? const Color(0xFF10B981).withValues(alpha: 0.5)
            : null,
      ),
    );
  }
}
