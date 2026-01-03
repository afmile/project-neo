import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';

class WallThreadsComposerLauncher extends StatelessWidget {
  final UserEntity currentUser;
  final UserEntity profileUser;
  final bool isSelfProfile;
  final VoidCallback onTap;

  const WallThreadsComposerLauncher({
    super.key,
    required this.currentUser,
    required this.profileUser,
    required this.isSelfProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderText = isSelfProfile
        ? '¿Qué novedades tienes?'
        : 'Publica en el muro de @${profileUser.username}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12, // Altura compacta total ~52dp
        ),
        child: Row(
          children: [
            // Avatar del usuario actual (40dp)
            CircleAvatar(
              radius: 20, // 40dp diameter
              backgroundColor: NeoColors.accent.withValues(alpha: 0.15),
              backgroundImage: currentUser.avatarUrl != null &&
                      currentUser.avatarUrl!.isNotEmpty
                  ? NetworkImage(currentUser.avatarUrl!)
                  : null,
              child: currentUser.avatarUrl == null ||
                      currentUser.avatarUrl!.isEmpty
                  ? Text(
                      currentUser.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: NeoColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // Placeholder text (sin bordes, sin decoración)
            Expanded(
              child: Text(
                placeholderText,
                style: const TextStyle(
                  color: Color(0xFF616161), // Gris medio (mismo que timestamps)
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
