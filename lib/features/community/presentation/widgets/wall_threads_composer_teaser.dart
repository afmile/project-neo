/// Project Neo - Wall Threads Composer Teaser
///
/// Compact teaser widget that opens the full composer modal
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';

class WallThreadsComposerTeaser extends StatelessWidget {
  final UserEntity currentUser;
  final UserEntity profileUser;
  final bool isSelfProfile;
  final VoidCallback onTap;

  const WallThreadsComposerTeaser({
    super.key,
    required this.currentUser,
    required this.profileUser,
    required this.isSelfProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = isSelfProfile
        ? 'Publica en tu muro'
        : 'Publica en el muro de @${profileUser.username}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: NeoColors.accent.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: NeoColors.accent.withValues(alpha: 0.2),
              backgroundImage: currentUser.avatarUrl != null && currentUser.avatarUrl!.isNotEmpty
                  ? NetworkImage(currentUser.avatarUrl!)
                  : null,
              child: currentUser.avatarUrl == null || currentUser.avatarUrl!.isEmpty
                  ? Text(
                      currentUser.username.isNotEmpty 
                          ? currentUser.username[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(
                        color: NeoColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Placeholder text
            Expanded(
              child: Text(
                placeholder,
                style: TextStyle(
                  color: NeoColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
            ),
            
            // Icon hint
            Icon(
              Icons.edit_outlined,
              size: 20,
              color: NeoColors.textTertiary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
