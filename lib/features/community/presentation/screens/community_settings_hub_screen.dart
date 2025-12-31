/// Project Neo - Community Management Screen
///
/// Admin and management interface for community leaders and owners
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/local_identity_providers.dart';
import '../providers/title_request_providers.dart';
import '../widgets/bento_card_widget.dart';

class CommunityManagementScreen extends ConsumerWidget {
  final CommunityEntity community;

  const CommunityManagementScreen({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final localIdentityAsync = ref.watch(myLocalIdentityProvider(community.id));
    
    final themeColor = _parseColor(community.theme.primaryColor);

    return Theme(
      data: NeoTheme.darkTheme(accentColor: themeColor),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Dark blue-gray
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestión de Comunidad',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                community.title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
          ),
        ),
        body: localIdentityAsync.when(
          data: (identity) {
            final role = identity?.role?.toLowerCase() ?? '';
            final isOwner = user?.id == community.ownerId;
            final isLeader = isOwner || 
                           role == 'leader' || 
                           role == 'curator' || 
                           role == 'mod';

            return _buildContent(
              context,
              ref,
              themeColor,
              isLeader: isLeader,
              isOwner: isOwner,
              userId: user?.id ?? '',
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildContent(
            context,
            ref,
            themeColor,
            isLeader: false,
            isOwner: false,
            userId: user?.id ?? '',
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Color themeColor, {
    required bool isLeader,
    required bool isOwner,
    required String userId,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A), // Dark blue-gray
            const Color(0xFF020617), // Almost black
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Leader Section (Leaders+)
          if (isLeader) ...[
            const SettingsSectionHeader(title: 'Gestión'),
            _buildLeaderSection(context, ref, themeColor),
          ],

          // Owner Section (Owners only)
          if (isOwner) ...[
            const SettingsSectionHeader(title: 'Administración'),
            _buildOwnerSection(context, themeColor),
          ],

          // If not a leader, show message
          if (!isLeader) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Solo para Líderes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes permisos para gestionar esta comunidad',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLeaderSection(BuildContext context, WidgetRef ref, Color themeColor) {
    // Get pending requests count for badge
    final pendingRequestsAsync = ref.watch(pendingTitleRequestsProvider(community.id));
    final pendingCount = pendingRequestsAsync.when(
      data: (requests) => requests.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Column(
      children: [
        BentoCard(
          icon: Icons.request_page_outlined,
          title: 'Solicitudes de Títulos',
          subtitle: 'Aprobar o rechazar títulos personalizados',
          accentColor: const Color(0xFF10B981),
          badge: pendingCount > 0 ? '$pendingCount' : null,
          onTap: () {
            context.pushNamed(
              'manage-title-requests',
              pathParameters: {'communityId': community.id},
              extra: {
                'name': community.title,
                'color': themeColor,
              },
            );
          },
        ),
        const SizedBox(height: 12),
        BentoCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Gestionar Roles',
          subtitle: 'Asignar y modificar roles de miembros',
          accentColor: const Color(0xFF3B82F6),
          onTap: () {
            // TODO: Navigate to role management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOwnerSection(BuildContext context, Color themeColor) {
    return Column(
      children: [
        BentoCard(
          icon: Icons.edit_outlined,
          title: 'Editar Comunidad',
          subtitle: 'Nombre, descripción, tema y privacidad',
          accentColor: const Color(0xFFEC4899),
          onTap: () {
            context.pushNamed(
              'edit-community',
              pathParameters: {'id': community.id},
              extra: {'community': community},
            );
          },
        ),
        const SizedBox(height: 12),
        BentoCard(
          icon: Icons.extension_outlined,
          title: 'Módulos',
          subtitle: 'Activa o desactiva funcionalidades',
          accentColor: const Color(0xFF06B6D4),
          onTap: () {
            // TODO: Navigate to modules (Neo Studio)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente')),
            );
          },
        ),
        const SizedBox(height: 12),
        BentoCard(
          icon: Icons.bar_chart_outlined,
          title: 'Estadísticas',
          subtitle: 'Métricas y análisis de la comunidad',
          accentColor: const Color(0xFF8B5CF6),
          onTap: () {
            // TODO: Navigate to stats (Neo Studio)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente')),
            );
          },
        ),
        const SizedBox(height: 12),
        BentoCard(
          icon: Icons.people_outline,
          title: 'Administrar Miembros',
          subtitle: 'Gestiona miembros y permisos',
          accentColor: const Color(0xFFF59E0B),
          onTap: () {
            // TODO: Navigate to members admin (Neo Studio)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente')),
            );
          },
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse('0xFF${hexColor.replaceAll('#', '')}'));
    } catch (e) {
      return NeoColors.accent;
    }
  }
}
