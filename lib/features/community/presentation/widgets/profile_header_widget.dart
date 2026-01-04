/// Project Neo - Profile Header Widget
///
/// Unified header for both self-profile and other-user profiles
/// Shows avatar, username, level, staff roles, custom titles, stats, and actions
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/models/community_title_model.dart';

class ProfileHeaderWidget extends StatelessWidget {
  // User data
  final UserEntity profileUser;
  final bool isSelfProfile;
  
  // Stats
  final int followersCount;
  final int followingCount;
  
  // Roles and titles
  final String? staffRole; // 'LÍDER' or 'MOD' or null
  final List<CommunityTitle> titles;
  
  // Callbacks
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;
  final VoidCallback onMenuTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileHeaderWidget({
    super.key,
    required this.profileUser,
    required this.isSelfProfile,
    required this.followersCount,
    required this.followingCount,
    required this.staffRole,
    required this.titles,
    this.onFollowTap,
    this.onMessageTap,
    required this.onMenuTap,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 24),
      child: Column(
        children: [
          // Menu ⋯ (top right)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
              onPressed: onMenuTap,
            ),
          ),
          
          // Avatar
          _buildAvatar(),
          
          const SizedBox(height: 16),
          
          // Username + Level
          _buildUsernameAndLevel(),
          
          const SizedBox(height: 12),
          
          // Roles + Titles
          _buildTitles(),
          
          const SizedBox(height: 16),
          
          // Stats
          _buildStats(),
          
          // Action buttons (only if other profile)
          if (!isSelfProfile) ...[
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: NeoColors.accent,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: NeoColors.accent.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60, // 120dp diameter
          backgroundColor: NeoColors.accent.withValues(alpha: 0.15),
          backgroundImage: profileUser.avatarUrl != null &&
                  profileUser.avatarUrl!.isNotEmpty
              ? NetworkImage(profileUser.avatarUrl!)
              : null,
          child: profileUser.avatarUrl == null || profileUser.avatarUrl!.isEmpty
              ? Text(
                  profileUser.username[0].toUpperCase(),
                  style: const TextStyle(
                    color: NeoColors.accent,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildUsernameAndLevel() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Username
          Text(
            '@${profileUser.username}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Level badge
          _buildLevelBadge(),
        ],
      ),
    );
  }

  Widget _buildLevelBadge() {
    // TODO: Get real level from user data
    final int level = 5; // Placeholder
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NeoColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeoColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Nv $level',
        style: const TextStyle(
          color: NeoColors.accent,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTitles() {
    final List<Widget> titleWidgets = [];
    
    // 1. STAFF ROLE (if exists) - ALWAYS FIRST
    if (staffRole != null) {
      titleWidgets.add(_buildStaffRolePill(staffRole!));
    }
    
    // 2. CUSTOM TITLES (max 3)
    for (final title in titles.take(3)) {
      titleWidgets.add(_buildCustomTitlePill(title));
    }
    
    if (titleWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: titleWidgets,
      ),
    );
  }

  Widget _buildStaffRolePill(String role) {
    final bool isLeader = role == 'LÍDER';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLeader 
            ? const Color(0xFF8B5CF6)  // Purple for Leader
            : const Color(0xFF10B981), // Green for Mod
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isLeader 
                ? const Color(0xFF8B5CF6) 
                : const Color(0xFF10B981)).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLeader ? '👑' : '🛡️',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            role,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTitlePill(CommunityTitle title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: title.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title.text,
        style: TextStyle(
          color: title.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Followers
          InkWell(
            onTap: onFollowersTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$followersCount ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: 'Seguidores',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Separator
          Text(
            ' · ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          
          // Following
          InkWell(
            onTap: onFollowingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$followingCount ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: 'Siguiendo',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Follow button
          _buildFollowButton(),
          
          const SizedBox(width: 12),
          
          // Message button
          _buildMessageButton(),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    // TODO: Get real follow/friendship status from providers
    final bool isFollowing = false; // Placeholder
    final bool areFriends = false; // Placeholder
    
    String buttonText;
    Color buttonColor;
    Color textColor;
    
    if (areFriends) {
      buttonText = '🤝 Amigos';
      buttonColor = Colors.grey[800]!;
      textColor = Colors.white;
    } else if (isFollowing) {
      buttonText = 'Siguiendo';
      buttonColor = Colors.grey[800]!;
      textColor = Colors.white;
    } else {
      buttonText = 'Seguir';
      buttonColor = NeoColors.accent;
      textColor = Colors.white;
    }
    
    return ElevatedButton(
      onPressed: onFollowTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
      child: Text(
        buttonText,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return OutlinedButton(
      onPressed: onMessageTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: NeoColors.accent,
        side: const BorderSide(
          color: NeoColors.accent,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Text(
        'Mensaje',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
