import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/neo_theme.dart';
import '../../../domain/entities/community_entity.dart';
import '../../providers/community_members_provider.dart';
import '../../providers/community_providers.dart';
import '../../providers/local_identity_providers.dart';

// Provider to fetch banned members
final bannedMembersProvider = FutureProvider.family.autoDispose<List<CommunityMember>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  final result = await repo.fetchBannedMembers(communityId: communityId);
  return result.fold(
    (failure) => throw failure,
    (members) => members,
  );
});

class CommunityBannedUsersScreen extends ConsumerWidget {
  final String communityId;

  const CommunityBannedUsersScreen({
    super.key, 
    required this.communityId
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannedAsync = ref.watch(bannedMembersProvider(communityId));
    final currentUserAsync = ref.watch(myLocalIdentityProvider(communityId));
    
    // Determine Permissions
    final canUnban = currentUserAsync.when(
      data: (identity) {
        final role = identity?.role?.toLowerCase();
        // Founder (owner) or Leader can unban. Moderators cannot.
        // Note: owner check usually done via community entity, but identity.role == 'owner' works too
        // if identity logic maps owner correctly. 
        // Safer: Logic in repo is strict. UI logic:
        return role == 'owner' || role == 'leader';
      },
      loading: () => false,
      error: (_, __) => false,
    );

    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        backgroundColor: NeoColors.background,
        elevation: 0,
        title: const Text(
          'Usuarios Baneados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: bannedAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay usuarios baneados',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildBannedUserTile(context, ref, member, canUnban);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildBannedUserTile(
    BuildContext context, 
    WidgetRef ref, 
    CommunityMember member, 
    bool canUnban
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Neo Card Color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
          backgroundColor: Colors.grey[800],
          child: member.avatarUrl == null 
              ? Text(member.username[0].toUpperCase(), style: const TextStyle(color: Colors.white))
              : null,
        ),
        title: Text(
          member.nickname ?? member.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.nickname != null)
              Text(
                '@${member.username}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            if (member.bannedAt != null)
               Text(
                'Baneado el ${_formatDate(member.bannedAt!)}',
                style: TextStyle(color: NeoColors.error.withOpacity(0.8), fontSize: 12),
              ),
          ],
        ),
        trailing: canUnban 
            ? TextButton.icon(
                onPressed: () => _confirmUnban(context, ref, member),
                icon: const Icon(Icons.undo, size: 16, color: NeoColors.accent),
                label: const Text('Readmitir', style: TextStyle(color: NeoColors.accent)),
                style: TextButton.styleFrom(
                  backgroundColor: NeoColors.accent.withOpacity(0.1),
                ),
              )
            : Tooltip(
                message: 'Solo Líderes pueden readmitir',
                child: Icon(Icons.lock, color: Colors.white.withOpacity(0.3)),
              ),
      ),
    );
  }

  void _confirmUnban(BuildContext context, WidgetRef ref, CommunityMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Readmitir usuario?', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que quieres quitar el ban a ${member.nickname ?? member.username}?\nPodrá volver a entrar y participar en la comunidad.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                final repo = ref.read(communityRepositoryProvider);
                final result = await repo.unbanMember(
                  communityId: communityId,
                  userId: member.id,
                );
                
                result.fold(
                  (l) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${l.message}')),
                  ),
                  (r) {
                    // Success
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario readmitido correctamente')),
                    );
                    // Refresh list
                    ref.invalidate(bannedMembersProvider(communityId));
                  },
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Error inesperado: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.accent,
            ),
            child: const Text('Readmitir'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
