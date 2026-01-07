/// Project Neo - Member Actions Sheet
///
/// Modal that shows available actions for community members
/// Only visible for leaders/moderators to manage roles
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/community_providers.dart';
import '../providers/community_members_provider.dart';

/// Shows a bottom sheet with member management options
void showMemberActionsSheet(
  BuildContext context, {
  required String userId,
  required String communityId,
  required String username,
  required bool currentIsFounder,
  required bool currentIsLeader,
  required bool currentIsModerator,
  required bool viewerIsLeader,
  bool currentIsMuted = false,
  bool currentIsBanned = false,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => MemberActionsSheet(
      userId: userId,
      communityId: communityId,
      username: username,
      currentIsFounder: currentIsFounder,
      currentIsLeader: currentIsLeader,
      currentIsModerator: currentIsModerator,
      viewerIsLeader: viewerIsLeader,
      currentIsMuted: currentIsMuted,
      currentIsBanned: currentIsBanned,
    ),
  );
}

/// Modal that shows available actions for a member
/// Only leaders can manage roles
class MemberActionsSheet extends ConsumerStatefulWidget {
  final String userId;
  final String communityId;
  final String username;
  final bool currentIsFounder;
  final bool currentIsLeader;
  final bool currentIsModerator;
  final bool viewerIsLeader;
  final bool currentIsMuted;
  final bool currentIsBanned;

  const MemberActionsSheet({
    super.key,
    required this.userId,
    required this.communityId,
    required this.username,
    required this.currentIsFounder,
    required this.currentIsLeader,
    required this.currentIsModerator,
    required this.viewerIsLeader,
    this.currentIsMuted = false,
    this.currentIsBanned = false,
  });

  @override
  ConsumerState<MemberActionsSheet> createState() => _MemberActionsSheetState();
}

class _MemberActionsSheetState extends ConsumerState<MemberActionsSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: NeoColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gestionar: @${widget.username}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estado actual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  'Estado actual: ',
                  style: TextStyle(color: Colors.grey),
                ),
                if (widget.currentIsFounder)
                  const Text(
                    'FUNDADOR',
                    style: TextStyle(
                      color: Color(0xFFF59E0B), // Amber
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (widget.currentIsLeader)
                  const Text(
                    'LÍDER',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (widget.currentIsModerator)
                  const Text(
                    'MODERADOR',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Text(
                    'Miembro',
                    style: TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Acciones disponibles (solo si viewer es líder)
          if (widget.viewerIsLeader && !_isLoading) ...[
            const Text(
              'Acciones Disponibles:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // Founder protection message
            if (widget.currentIsFounder) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.amber[200], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este usuario es el Fundador de la comunidad y no puede ser removido.',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Promover a Líder (solo si NO es founder y NO es líder)
            if (!widget.currentIsFounder && !widget.currentIsLeader)
              _ActionTile(
                icon: Icons.star,
                title: 'Promover a Líder',
                subtitle: 'Tendrá permisos totales',
                color: Colors.amber,
                onTap: () => _showPromoteDialog(isLeader: true),
              ),

            const SizedBox(height: 8),

            // Promover a Moderador (solo si NO es founder, NO es mod, y NO es líder)
            if (!widget.currentIsFounder && !widget.currentIsModerator && !widget.currentIsLeader)
              _ActionTile(
                icon: Icons.shield,
                title: 'Promover a Moderador',
                subtitle: 'Podrá moderar contenido',
                color: Colors.blue,
                onTap: () => _showPromoteDialog(isLeader: false),
              ),

            // Degradar (solo si tiene rol pero NO es founder)
            if (!widget.currentIsFounder && (widget.currentIsLeader || widget.currentIsModerator)) ...[
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.arrow_downward,
                title: 'Degradar a Miembro',
                subtitle: 'Remover permisos especiales',
                color: Colors.orange,
                onTap: _showDemoteDialog,
              ),
            ],

            const SizedBox(height: 12),
            Divider(color: Colors.grey[700]),
            const SizedBox(height: 12),
          ],

          // MODERACIÓN: Mute/Ban (solo para leaders/mods, nunca founders)
          if (widget.viewerIsLeader && !widget.currentIsFounder) ...[
            Text(
              'Moderación',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            
            // Mute / Unmute
            if (!widget.currentIsMuted)
              _ActionTile(
                icon: Icons.volume_off,
                title: 'Silenciar Usuario',
                subtitle: 'No podrá publicar ni comentar',
                color: Colors.orange,
                onTap: _showMuteDialog,
              )
            else
              _ActionTile(
                icon: Icons.volume_up,
                title: 'Quitar Silencio',
                subtitle: 'Permitir publicar y comentar',
                color: Colors.green,
                onTap: _unmuteUser,
              ),
            
            const SizedBox(height: 8),
            
            // Ban / Unban
            if (!widget.currentIsBanned)
              _ActionTile(
                icon: Icons.block,
                title: 'Banear de Comunidad',
                subtitle: 'Expulsar permanentemente',
                color: Colors.red,
                onTap: _showBanDialog,
              )
            else
              _ActionTile(
                icon: Icons.check_circle,
                title: 'Quitar Ban',
                subtitle: 'Permitir volver a la comunidad',
                color: Colors.green,
                onTap: _unbanUser,
              ),
            
            const SizedBox(height: 12),
            Divider(color: Colors.grey[700]),
          ],

          // Loading state
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: NeoColors.accent),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showPromoteDialog({required bool isLeader}) {
    final role = isLeader ? 'Líder' : 'Moderador';
    final icon = isLeader ? '👑' : '🛡️';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Promover a $role',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de promover a @${widget.username} a $icon $role?\n\n'
          'Esta persona tendrá permisos ${isLeader ? 'totales' : 'de moderación'} en la comunidad.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _promoteUser(isLeader: isLeader);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLeader ? Colors.amber : Colors.blue,
            ),
            child: const Text(
              'Promover',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Degradar a Miembro',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de remover los permisos especiales de @${widget.username}?\n\n'
          'Volverá a ser un miembro regular.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _demoteUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text(
              'Degradar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promoteUser({required bool isLeader}) async {
    setState(() => _isLoading = true);

    try {
      print('🟡 DEBUG: Promocionando usuario ${widget.userId}...');

      final repo = ref.read(communityRepositoryProvider);

      final result = await repo.updateMemberRoles(
        userId: widget.userId,
        communityId: widget.communityId,
        isLeader: isLeader,
        isModerator: true, // If leader OR moderator, set mod to true
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (_) {
          // Invalidate providers to refresh
          ref.invalidate(communityMembersProvider(widget.communityId));

          if (mounted) {
            Navigator.pop(context); // Close sheet
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ @${widget.username} ahora es ${isLeader ? 'Líder' : 'Moderador'}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );

      print('🟢 DEBUG: Promoción exitosa');
    } catch (e) {
      print('🔴 ERROR promoviendo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demoteUser() async {
    setState(() => _isLoading = true);

    try {
      print('🟡 DEBUG: Degradando usuario ${widget.userId}...');

      final repo = ref.read(communityRepositoryProvider);

      final result = await repo.updateMemberRoles(
        userId: widget.userId,
        communityId: widget.communityId,
        isLeader: false,
        isModerator: false,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (_) {
          // Invalidate providers to refresh
          ref.invalidate(communityMembersProvider(widget.communityId));

          if (mounted) {
            Navigator.pop(context); // Close sheet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Usuario degradado a miembro regular'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );

      print('🟢 DEBUG: Degradación exitosa');
    } catch (e) {
      print('🔴 ERROR degradando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTE/BAN METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showMuteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Silenciar Usuario', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Silenciar a @${widget.username}?\n\n'
          'No podrá publicar ni comentar, pero seguirá en la comunidad.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _muteUser();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Silenciar'),
          ),
        ],
      ),
    );
  }

  Future<void> _muteUser() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(communityRepositoryProvider);
      final result = await repo.muteUser(
        userId: widget.userId,
        communityId: widget.communityId,
        reason: 'Silenciado por moderador',
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (_) {
          ref.invalidate(communityMembersProvider(widget.communityId));
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Usuario silenciado'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unmuteUser() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(communityRepositoryProvider);
      final result = await repo.unmuteUser(
        userId: widget.userId,
        communityId: widget.communityId,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(communityMembersProvider(widget.communityId));
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Silencio removido')),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('⚠️ Banear Usuario', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Banear a @${widget.username}?\n\n'
          'Será expulsado de la comunidad y no podrá volver a entrar.\n\n'
          'Esta acción es PERMANENTE hasta que un líder la revierta.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _banUser();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Banear'),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(communityRepositoryProvider);
      final result = await repo.banUser(
        userId: widget.userId,
        communityId: widget.communityId,
        reason: 'Baneado por moderador',
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(communityMembersProvider(widget.communityId));
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Usuario baneado de la comunidad'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unbanUser() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(communityRepositoryProvider);
      final result = await repo.unbanUser(
        userId: widget.userId,
        communityId: widget.communityId,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error: ${failure.message}')),
            );
          }
        },
        (_) {
          ref.invalidate(communityMembersProvider(widget.communityId));
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Ban removido'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Widget tile for each action
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
