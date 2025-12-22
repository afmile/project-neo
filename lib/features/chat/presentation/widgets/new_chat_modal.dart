import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class NewChatModal extends StatelessWidget {
  const NewChatModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Nuevo Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          _buildOption(
            context: context,
            icon: Icons.person_add_rounded,
            label: 'Nuevo Chat Privado',
            subtitle: 'Conversa con un usuario',
            color: NeoColors.accent,
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to user selection screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seleccionar usuario - Próximamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildOption(
            context: context,
            icon: Icons.group_add_rounded,
            label: 'Crear Grupo Privado',
            subtitle: 'Invita múltiples usuarios',
            color: const Color(0xFF8B5CF6), // Purple
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to group creation screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crear grupo - Próximamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
