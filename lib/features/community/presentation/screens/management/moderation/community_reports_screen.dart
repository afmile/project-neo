/// Project Neo - Community Reports Screen
///
/// Moderation inbox for AI Sentinel and user-generated reports
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../data/repositories/community_moderation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// PROVIDER
// =============================================================================

final moderationRepositoryProvider = Provider<CommunityModerationRepository>((ref) {
  return CommunityModerationRepositoryImpl(Supabase.instance.client);
});

final communityReportsProvider = FutureProvider.family<List<CommunityReport>, String>((ref, communityId) async {
  final repository = ref.watch(moderationRepositoryProvider);
  final result = await repository.fetchCommunityReports(communityId: communityId);
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (reports) => reports,
  );
});

// =============================================================================
// SCREEN
// =============================================================================

class CommunityReportsScreen extends ConsumerWidget {
  final String communityId;

  const CommunityReportsScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(communityReportsProvider(communityId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Centro de Reportes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay reportes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Todo está en orden!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(communityReportsProvider(communityId));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _ReportCard(
                    report: reports[index],
                    onDismiss: () => _handleDismiss(context, ref, reports[index]),
                    onDeleteContent: () => _handleDeleteContent(context, ref, reports[index]),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error cargando reportes',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDismiss(BuildContext context, WidgetRef ref, CommunityReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Descartar Reporte', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que deseas descartar este reporte?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.amber),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(moderationRepositoryProvider);
      final result = await repository.dismissReport(
        reportId: report.id,
        resolutionNote: 'Descartado por moderador',
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${failure.message}')),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte descartado')),
          );
          ref.invalidate(communityReportsProvider(communityId));
        },
      );
    }
  }

  Future<void> _handleDeleteContent(BuildContext context, WidgetRef ref, CommunityReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Eliminar Contenido', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este contenido? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(moderationRepositoryProvider);
      
      // Determine entity type
      final entityType = report.postId != null ? 'post' : 'comment';
      final entityId = report.postId ?? report.commentId!;

      // Delete content
      final deleteResult = await repository.deleteContent(
        entityType: entityType,
        entityId: entityId,
      );

      // Resolve report
      final resolveResult = await repository.resolveReport(
        reportId: report.id,
        resolutionNote: 'Contenido eliminado',
      );

      if (context.mounted) {
        deleteResult.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${failure.message}')),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contenido eliminado y reporte resuelto')),
            );
            ref.invalidate(communityReportsProvider(communityId));
          },
        );
      }
    }
  }
}

// =============================================================================
// REPORT CARD WIDGET
// =============================================================================

class _ReportCard extends StatelessWidget {
  final CommunityReport report;
  final VoidCallback onDismiss;
  final VoidCallback onDeleteContent;

  const _ReportCard({
    required this.report,
    required this.onDismiss,
    required this.onDeleteContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F2937).withOpacity(0.8),
            const Color(0xFF111827).withOpacity(0.9),
          ],
        ),
        border: Border.all(
          color: report.isCritical 
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : const Color(0xFFF59E0B).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (report.isCritical 
                ? const Color(0xFFEF4444)
                : const Color(0xFFF59E0B)).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reporter + Priority Badge
            Row(
              children: [
                // AI Sentinel or User Avatar
                if (report.isAIReport)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: report.reporterAvatar != null
                        ? NetworkImage(report.reporterAvatar!)
                        : null,
                    child: report.reporterAvatar == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                const SizedBox(width: 12),
                
                // Reporter name
                Expanded(
                  child: Text(
                    report.isAIReport ? '🤖 AI SENTINEL' : '@${report.reporterUsername ?? "Unknown"}',
                    style: TextStyle(
                      color: report.isAIReport 
                          ? const Color(0xFF8B5CF6)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: report.isCritical 
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (report.isCritical)
                        const Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                      if (report.isCritical) const SizedBox(width: 4),
                      Text(
                        report.priority.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(color: Colors.white24, height: 24),
            
            // Reason
            Text(
              report.reason,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text(
                report.description!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Accused user
            Row(
              children: [
                Text(
                  'Acusado:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '@${report.accusedUsername}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Timestamp
            Text(
              timeago.format(report.createdAt, locale: 'es'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Descartar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDeleteContent,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Borrar Contenido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
