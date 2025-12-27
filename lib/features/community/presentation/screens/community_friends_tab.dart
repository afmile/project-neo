/// Project Neo - Community Friends Tab
///
/// Shows real community members with online status indicators
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/community_members_provider.dart';
import '../providers/community_presence_provider.dart';

class CommunityFriendsTab extends ConsumerWidget {
  final String communityId;

  const CommunityFriendsTab({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(communityMembersProvider(communityId));
    final presenceState = ref.watch(communityPresenceProvider(communityId));

    return membersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: NeoColors.accent),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error al cargar miembros',
              style: NeoTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: NeoTextStyles.bodySmall.copyWith(color: NeoColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👥', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'No hay miembros aún',
                  style: NeoTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(NeoSpacing.md),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isOnline = presenceState.isUserOnline(member.id);

            return _MemberTile(
              member: member,
              isOnline: isOnline,
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/community-user-profile',
                  arguments: {
                    'userId': member.id,
                    'communityId': communityId,
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CommunityMember member;
  final bool isOnline;
  final VoidCallback onTap;

  const _MemberTile({
    required this.member,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: NeoSpacing.sm,
        vertical: NeoSpacing.xs,
      ),
      leading: Stack(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: NeoColors.accent.withValues(alpha: 0.2),
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: NeoColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          // Online indicator
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981), // Green
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        member.username,
        style: NeoTextStyles.bodyLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        member.roleDisplayName,
        style: NeoTextStyles.bodySmall.copyWith(
          color: _getRoleColor(member.role),
        ),
      ),
      trailing: isOnline
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return const Color(0xFFFFD700); // Gold
      case 'agent':
        return const Color(0xFFEC4899); // Pink
      case 'leader':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return NeoColors.textSecondary;
    }
  }
}
