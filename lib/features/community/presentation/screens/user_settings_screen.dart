/// Project Neo - User Settings Screen
///
/// Personal configuration screen accessible from user profile menu
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../widgets/bento_card_widget.dart';

class UserSettingsScreen extends StatelessWidget {
  final String communityId;
  final String communityName;
  final Color themeColor;

  const UserSettingsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NeoTheme.darkTheme(accentColor: themeColor),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
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
                'Mi Configuración',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                communityName,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SettingsSectionHeader(title: 'Personalización'),
              
              // Mis Títulos
              BentoCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Mis Títulos',
                subtitle: 'Reordena y gestiona tus títulos',
                accentColor: const Color(0xFFF59E0B), // Amber
                onTap: () {
                  context.pushNamed(
                    'user-titles-settings',
                    pathParameters: {'communityId': communityId},
                    extra: {
                      'name': communityName,
                      'color': themeColor,
                    },
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              // Mi Identidad Local
              BentoCard(
                icon: Icons.person_outline,
                title: 'Mi Identidad Local',
                subtitle: 'Edita tu perfil en esta comunidad',
                accentColor: const Color(0xFF8B5CF6), // Purple
                onTap: () {
                  context.pushNamed(
                    'local-identity',
                    pathParameters: {'communityId': communityId},
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              // Solicitar Título
              BentoCard(
                icon: Icons.add_circle_outline,
                title: 'Solicitar Título',
                subtitle: 'Crea un título personalizado',
                accentColor: const Color(0xFF10B981), // Green
                onTap: () {
                  context.pushNamed(
                    'request-title',
                    pathParameters: {'communityId': communityId},
                    extra: {
                      'name': communityName,
                      'color': themeColor,
                    },
                  );
                },
              ),
              
              const SettingsSectionHeader(title: 'Preferencias'),
              
              // Mis Notificaciones
              BentoCard(
                icon: Icons.notifications_outlined,
                title: 'Mis Notificaciones',
                subtitle: 'Gestiona alertas de esta comunidad',
                accentColor: themeColor,
                onTap: () {
                  context.pushNamed(
                    'community-settings',
                    pathParameters: {'id': communityId},
                    extra: {
                      'name': communityName,
                      'color': themeColor,
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
