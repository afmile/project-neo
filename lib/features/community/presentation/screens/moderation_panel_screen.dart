/// Project Neo - Moderation Panel Screen
///
/// Screen for community leaders/moderators to review and resolve reports
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_card.dart';

class ModerationPanelScreen extends ConsumerWidget {
  final String communityId;

  const ModerationPanelScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pendingReportsProvider(communityId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Panel de Moderación'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showModerationInfo(context),
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reportes pendientes',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Todo está en orden!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingReportsProvider(communityId));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return ReportCard(
                  report: reports[index],
                  communityId: communityId,
                  onResolved: () {
                    ref.invalidate(pendingReportsProvider(communityId));
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
        error: (e, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error cargando reportes',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModerationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Panel de Moderación',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Aquí puedes revisar y gestionar los reportes de la comunidad.\n\n'
          'Acciones disponibles:\n'
          '• Descartar: El reporte no procede\n'
          '• Advertir: Enviar advertencia al usuario\n'
          '• Banear: Expulsar de la comunidad\n\n'
          'Todos los reportes resueltos quedan registrados.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
