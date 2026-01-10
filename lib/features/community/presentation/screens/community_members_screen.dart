/// Project Neo - Community Members Screen
///
/// Redesigned tab layout with Community and Friends tabs
/// Features: Online grid, leadership cards, new members, and friends list
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/community_members_provider.dart';
import '../providers/community_presence_provider.dart';
import 'public_user_profile_screen.dart';
import 'community_user_profile_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CommunityMembersScreen extends ConsumerStatefulWidget {
  final String communityId;
  final VoidCallback onSwitchToProfileTab;
  
  const CommunityMembersScreen({
    super.key,
    required this.communityId,
    required this.onSwitchToProfileTab,
  });
  
  @override
  ConsumerState<CommunityMembersScreen> createState() =>
      _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends ConsumerState<CommunityMembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToProfile(String userId) {
    // Navigate to public profile (correct UI design)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PublicUserProfileScreen(
          userId: userId,
          communityId: widget.communityId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Comunidad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent, // Remove white line
          indicatorColor: NeoColors.accent,
          labelColor: NeoColors.accent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'COMUNIDAD'),
            Tab(text: 'AMIGOS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CommunityTab(
            communityId: widget.communityId,
            onUserTap: _navigateToProfile,
            onSwitchToProfileTab: widget.onSwitchToProfileTab,
          ),
          _FriendsTab(
            communityId: widget.communityId,
            onUserTap: _navigateToProfile,
            // Friends tab might need it too eventually
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB A: COMUNIDAD (Public)
// ============================================================================

class _CommunityTab extends ConsumerWidget {
  final String communityId;
  final Function(String userId) onUserTap;
  final VoidCallback onSwitchToProfileTab; // New callback

  const _CommunityTab({
    required this.communityId,
    required this.onUserTap,
    required this.onSwitchToProfileTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(communityMembersProvider(communityId));
    final presenceState = ref.watch(communityPresenceProvider(communityId));
    final currentUser = ref.watch(currentUserProvider); // Watch current user for comparison

    return membersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: NeoColors.accent),
      ),
      error: (error, _) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
      data: (members) {
        // Deduplicate members just in case
        final uniqueMembers = { for (var m in members) m.id : m }.values.toList();

        // Filter online members
        final onlineMembers = uniqueMembers
            .where((m) => presenceState.isUserOnline(m.id))
            .toList();

        // Filter by role for leadership section
        final leaders = uniqueMembers
            .where((m) => ['owner', 'leader', 'agent'].contains(m.role))
            .toList();
            
        // Filter moderators
        final moderators = uniqueMembers
            .where((m) => m.role == 'moderator')
            .toList();

        // Sort by created_at for new members (most recent first)
        final sortedMembers = List<CommunityMember>.from(uniqueMembers)
          ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
        final newMembers = sortedMembers.take(10).toList();

        // Wrapper for tap handling to intercept self-taps
        void handleUserTap(String userId) {
          if (userId == currentUser?.id) {
            onSwitchToProfileTab();
          } else {
            onUserTap(userId);
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(NeoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Online Users Grid
              _SectionHeader(
                title: 'Conectados',
                count: onlineMembers.length,
                icon: Icons.circle,
                iconColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _OnlineUsersGrid(
                members: onlineMembers,
                presenceState: presenceState,
                onUserTap: handleUserTap,
              ),

              const SizedBox(height: 24), // Spacing Reduced

              // Section 2: Leadership
              if (leaders.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Liderazgo',
                  count: leaders.length,
                  icon: Icons.star,
                  iconColor: const Color(0xFFFFD700),
                ),
                const SizedBox(height: 12),
                _StaffList(
                  members: leaders,
                  onUserTap: handleUserTap,
                ),
                const SizedBox(height: 24), // Spacing Reduced
              ],

              // Section 3: Moderators (New Section)
              _SectionHeader(
                title: 'Moderadores',
                count: moderators.length,
                icon: Icons.security,
                iconColor: const Color(0xFF4CAF50), // Green for Mod
              ),
              const SizedBox(height: 12),
              if (moderators.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "No hay moderadores actualmente",
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                )
              else
                _StaffList(
                  members: moderators,
                  onUserTap: handleUserTap,
                ),
                
              const SizedBox(height: 24), // Spacing Reduced

              // Section 4: New Members
              _SectionHeader(
                title: 'Recientes',
                count: newMembers.length,
                icon: Icons.fiber_new,
                iconColor: NeoColors.accent,
              ),
              const SizedBox(height: 12),
              _NewMembersList(
                members: newMembers,
                onUserTap: handleUserTap,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB B: AMIGOS (Private)
// ============================================================================

class _FriendsTab extends ConsumerWidget {
  final String communityId;
  final Function(String userId) onUserTap;

  const _FriendsTab({
    required this.communityId,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual friends provider when implemented
    // For now, showing message that friends feature is coming
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Lista de Amigos',
            style: NeoTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente podrás ver tus amigos aquí',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: NeoTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _OnlineUsersGrid extends StatelessWidget {
  final List<CommunityMember> members;
  final CommunityPresenceState presenceState;
  final Function(String userId) onUserTap;

  const _OnlineUsersGrid({
    required this.members,
    required this.presenceState,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Nadie conectado ahora',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180, // Increased height to prevent overflow (avatars + text)
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return _OnlineAvatarCell(
            member: member,
            onTap: () => onUserTap(member.id),
          );
        },
      ),
    );
  }
}

class _OnlineAvatarCell extends StatelessWidget {
  final CommunityMember member;
  final VoidCallback onTap;

  const _OnlineAvatarCell({
    required this.member,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
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
              // Green dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 4),
          SizedBox(
            width: 64, // Constrain width to prevent overflow
            child: Text(
              member.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffList extends StatelessWidget {
  final List<CommunityMember> members;
  final Function(String userId) onUserTap;

  const _StaffList({
    required this.members,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final member = members[index];
          return _LeaderCard(
            member: member,
            onTap: () => onUserTap(member.id),
          );
        },
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final CommunityMember member;
  final VoidCallback onTap;

  const _LeaderCard({
    required this.member,
    required this.onTap,
  });

  Color _getRoleColor() {
    switch (member.role) {
      case 'owner':
        return const Color(0xFFFFD700); // Gold
      case 'leader':
        return const Color(0xFF8B5CF6); // Purple
      case 'agent':
        return const Color(0xFFEC4899); // Pink
      default:
        return NeoColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              roleColor.withValues(alpha: 0.3),
              Colors.grey[900]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: roleColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withValues(alpha: 0.3),
              backgroundImage: member.avatarUrl != null
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null
                  ? Icon(Icons.person, color: roleColor, size: 22)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              member.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: member.role == 'owner' 
                      ? [const Color(0xFFFFD700), const Color(0xFFFFA000)] // Gold
                      : member.role == 'leader' 
                          ? [const Color(0xFFBA68C8), const Color(0xFF9C27B0)] // Purple
                          : [const Color(0xFF66BB6A), const Color(0xFF43A047)], // Green
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Text(
                member.roleDisplayName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewMembersList extends StatelessWidget {
  final List<CommunityMember> members;
  final Function(String userId) onUserTap;

  const _NewMembersList({
    required this.members,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (_, __) => Divider(
        color: Colors.grey.withValues(alpha: 0.2),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          onTap: () => onUserTap(member.id),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: CircleAvatar(
            radius: 22,
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
                    ),
                  )
                : null,
          ),
          title: Text(
            member.username,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Se unió ${_formatJoinDate(member.joinedAt)}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: NeoColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Nuevo',
              style: TextStyle(
                color: NeoColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'hoy';
    } else if (diff.inDays == 1) {
      return 'ayer';
    } else if (diff.inDays < 7) {
      return 'hace ${diff.inDays} días';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'hace ${weeks} semana${weeks > 1 ? 's' : ''}';
    } else {
      final months = (diff.inDays / 30).floor();
      return 'hace ${months} mes${months > 1 ? 'es' : ''}';
    }
  }
}
