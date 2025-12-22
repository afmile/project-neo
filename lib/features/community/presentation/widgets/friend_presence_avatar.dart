/// Project Neo - Friend Presence Avatar
///
/// Displays a friend's avatar with online status and location
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/friend_presence.dart';

class FriendPresenceAvatar extends StatelessWidget {
  final FriendPresence presence;
  final VoidCallback? onTap;

  const FriendPresenceAvatar({
    super.key,
    required this.presence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NeoColors.accent.withValues(alpha: 0.2),
                    border: Border.all(
                      color: NeoColors.accent,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: NeoColors.accent,
                    size: 28,
                  ),
                ),
                
                // Online indicator
                if (presence.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981), // Green
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Username
            Text(
              presence.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 2),
            
            // Location indicator
            if (presence.isOnline && presence.location != PresenceLocation.offline)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: NeoColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      presence.location.emoji,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        presence.location.label,
                        style: TextStyle(
                          color: NeoColors.textTertiary,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
