
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/community_members_provider.dart';
import '../../providers/community_providers.dart';
import 'package:dartz/dartz.dart'; // For Either
import '../../../../../core/error/failures.dart'; // For Failure
import '../../../../../core/theme/neo_theme.dart';

class CommunityManageRolesScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityManageRolesScreen({
    super.key, 
    required this.communityId
  });

  @override
  ConsumerState<CommunityManageRolesScreen> createState() => _CommunityManageRolesScreenState();
}

class _CommunityManageRolesScreenState extends ConsumerState<CommunityManageRolesScreen> {
  String _searchQuery = '';

  void _showRoleOptions(BuildContext context, CommunityMember targetMember) {
    // 1. Get Current User Identity (to check permissions)
    final currentUserAsync = ref.read(communityMembersProvider(widget.communityId));
    
    // Safety check: wait for data or use cached
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Find "Me" in the members list to know MY role
    final members = currentUserAsync.valueOrNull;
    if (members == null) return;
    
    final me = members.firstWhere((m) => m.id == currentUserId, orElse: () => targetMember); 
    
    // 2. Define Authority Levels
    bool amIFounder = me.isFounder;
    bool amILeader = me.isLeader;
    
    // If I'm neither, I shouldn't be here, but double check
    if (!amIFounder && !amILeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No tienes permisos para gestionar roles."))
      );
      return;
    }

    // 3. Safety Check: Cannot edit yourself (UNLESS accepting/rejecting an invite)
    if (targetMember.id == currentUserId) {
      if (targetMember.pendingRole != null) {
        _showAcceptRejectDialog(context, targetMember);
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes editar tu propio rol aquí."))
      );
      return;
    }

    bool targetIsFounder = targetMember.isFounder;
    bool targetIsLeader = targetMember.isLeader;

    List<Widget> options = [];

    // --- HIERARCHY LOGIC ---
    // ... [Rest of the hierarchy logic remains the same] ...
    // CASE: Owner/Founder 
    if (amIFounder) {
       // Promoting/Demoting Leaders
       if (!targetIsLeader) {
         options.add(_buildOption(
           icon: Icons.shield,
           color: Colors.purpleAccent,
           label: "Ascender a Líder", 
           onTap: () => _updateRole(targetMember, 'leader')
         ));
       } else {
         options.add(_buildOption(
           icon: Icons.arrow_downward,
           color: Colors.redAccent,
           label: "Degradar a Miembro", 
           onTap: () => _updateRole(targetMember, 'member') 
         ));
       }

       // Promoting/Demoting Moderators
       if (!targetMember.isModerator) {
         options.add(_buildOption(
           icon: Icons.security,
           color: Colors.greenAccent,
           label: "Hacer Moderador", 
           onTap: () => _updateRole(targetMember, 'moderator')
         ));
       } else {
          if (!targetIsLeader) {
             options.add(_buildOption(
               icon: Icons.remove_circle_outline,
               color: Colors.orangeAccent,
               label: "Quitar Moderador", 
               onTap: () => _updateRole(targetMember, 'member')
             ));
          }
       }
    }

    // CASE: Leader 
    else if (amILeader) {
      if (targetIsFounder || targetIsLeader) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No puedes editar a un superior o igual."))
        );
        return; 
      }

      if (!targetMember.isModerator) {
         options.add(_buildOption(
           icon: Icons.security,
           color: Colors.greenAccent,
           label: "Hacer Moderador", 
           onTap: () => _updateRole(targetMember, 'moderator')
         ));
       } else {
         options.add(_buildOption(
           icon: Icons.remove_circle_outline,
           color: Colors.orangeAccent,
           label: "Quitar Moderador", 
           onTap: () => _updateRole(targetMember, 'member')
         ));
       }
    }

    // BAN LOGIC
    bool canBan = false;
    if (amIFounder) {
      canBan = true; 
    } else if (amILeader) {
       if (!targetIsFounder && !targetIsLeader) {
         canBan = true;
       }
    }

    if (canBan) {
       options.add(const SizedBox(height: 8));
       options.add(Container(height: 1, color: Colors.white10));
       options.add(const SizedBox(height: 8));
       
       options.add(_buildOption(
         icon: Icons.gavel_rounded,
         color: Colors.redAccent,
         label: "Expulsar de la Comunidad", 
         onTap: () => _confirmBan(targetMember)
       ));
    }

    if (options.isEmpty) return;

    showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text("Gestionar a ${targetMember.nickname ?? targetMember.username}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...options,
            const SizedBox(height: 24),
          ]
        ),
      )
    );
  }

  void _showAcceptRejectDialog(BuildContext context, CommunityMember member) {
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: const Color(0xFF1F2937),
         title: const Text("Propuesta de Ascenso", style: TextStyle(color: Colors.white)),
         content: Text(
           "Te han propuesto el cargo de ${member.pendingRole?.toUpperCase()}. ¿Deseas aceptar?",
           style: const TextStyle(color: Colors.white70),
         ),
         actions: [
           TextButton(
             onPressed: () {
               Navigator.pop(ctx);
               _respondToinvite(accept: false);
             },
             child: const Text("Rechazar", style: TextStyle(color: Colors.redAccent)),
           ),
           TextButton(
             onPressed: () {
               Navigator.pop(ctx);
               _respondToinvite(accept: true);
             },
             child: const Text("Aceptar", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
           ),
         ],
       )
     );
  }

  Future<void> _respondToinvite({required bool accept}) async {
    final repo = ref.read(communityRepositoryProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(accept ? "Aceptando..." : "Rechazando..."))
    );

    final Either<Failure, void> result;
    if (accept) {
      result = await repo.acceptRoleInvitation(communityId: widget.communityId);
    } else {
      result = await repo.rejectRoleInvitation(communityId: widget.communityId);
    }

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${failure.message}"), backgroundColor: Colors.red)),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? "¡Cargo aceptado!" : "Propuesta rechazada"), 
            backgroundColor: Colors.green
          )
        );
        ref.invalidate(communityMembersProvider(widget.communityId));
      }
    );
  }

  Widget _buildOption({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Close modal
        onTap();
      },
    );
  }

  Future<void> _updateRole(CommunityMember member, String newRole) async {
    final repo = ref.read(communityRepositoryProvider);
    
    // Check if it's a promotion (invitation) or demotion
    bool isPromotion = newRole != 'member'; // Simplified check

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isPromotion ? "Enviando invitación..." : "Actualizando rol..."))
    );

    final result = await repo.inviteMemberToRole(
      communityId: widget.communityId, 
      userId: member.id, 
      newRole: newRole
    );

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${failure.message}"), backgroundColor: Colors.red)),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPromotion ? "Invitación enviada correctamente" : "Rol actualizado correctamente"), 
            backgroundColor: Colors.green
          )
        );
        ref.invalidate(communityMembersProvider(widget.communityId));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(communityMembersProvider(widget.communityId));

    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        title: const Text("Gestionar Roles", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: membersAsync.when(
        data: (members) {
           // Filter members locally
           final filteredMembers = members.where((m) {
             final name = (m.nickname ?? m.username).toLowerCase();
             return name.contains(_searchQuery.toLowerCase());
           }).toList();

           if (filteredMembers.isEmpty) return const Center(child: Text("No se encontraron miembros", style: TextStyle(color: Colors.white54)));
           
           return ListView.separated(
             itemCount: filteredMembers.length,
             separatorBuilder: (_, __) => const Divider(color: Colors.white10),
             itemBuilder: (context, index) {
               final member = filteredMembers[index];
               final displayName = member.nickname ?? member.username;
               
               return ListTile(
                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 leading: CircleAvatar(
                   radius: 20,
                   backgroundColor: Colors.grey[800],
                   backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                   child: member.avatarUrl == null 
                       ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white)) 
                       : null,
                 ),
                 title: Text(
                    displayName, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                 ),
                 // SUBTITLE REMOVED to hide global username as requested
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     _buildRoleBadge(member),
                     if (member.pendingRole != null) ...[
                       const SizedBox(width: 8),
                       _badge("PROPUESTA: ${member.pendingRole!.toUpperCase()}", Colors.orangeAccent.withOpacity(0.2), Colors.orangeAccent),
                     ]
                   ],
                 ),
                 onTap: () => _showRoleOptions(context, member),
               );
             },
           );
        },
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
        loading: () => const Center(child: CircularProgressIndicator(color: NeoColors.accent)),
      ),
    );
  }

  Widget _buildRoleBadge(CommunityMember member) {
    if (member.isFounder) {
      return _badge("FUNDADOR", const Color(0xFFFFD700), const Color(0xFF3E2723));
    }
    if (member.isLeader) {
      return _badge("LÍDER", const Color(0xFFBA68C8), Colors.white);
    }
    if (member.isModerator) {
      return _badge("MOD", const Color(0xFF66BB6A), Colors.white);
    }
    return const SizedBox.shrink(); // No badge for members
  }

  Widget _badge(String text, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmBan(CommunityMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('¿Expulsar usuario?', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que quieres expulsar a ${member.nickname ?? member.username}?\nPerderá el acceso a la comunidad inmediatamente.',
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
              
              final repo = ref.read(communityRepositoryProvider);
              final result = await repo.banMember(
                communityId: widget.communityId,
                userId: member.id,
              );

              if (!mounted) return;

              result.fold(
                (l) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${l.message}'), backgroundColor: Colors.red),
                ),
                (r) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario expulsado correctamente'), backgroundColor: Colors.redAccent),
                  );
                  ref.invalidate(communityMembersProvider(widget.communityId));
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('EXPULSAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
