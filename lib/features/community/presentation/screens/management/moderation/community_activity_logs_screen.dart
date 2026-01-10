/// Project Neo - Community Activity Logs Screen
///
/// Forensic audit timeline for moderation actions and deleted content
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/repositories/community_moderation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

final moderationRepositoryProvider = Provider<CommunityModerationRepository>((ref) {
  return CommunityModerationRepositoryImpl(Supabase.instance.client);
});

final activityLogsProvider = FutureProvider.family<List<ActivityLog>, String>((ref, communityId) async {
  final repository = ref.watch(moderationRepositoryProvider);
  final result = await repository.fetchActivityLogs(communityId: communityId, limit: 100);
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (logs) => logs,
  );
});

// =============================================================================
// SCREEN
// =============================================================================

class CommunityActivityLogsScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityActivityLogsScreen({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<CommunityActivityLogsScreen> createState() => _CommunityActivityLogsScreenState();
}

class _CommunityActivityLogsScreenState extends ConsumerState<CommunityActivityLogsScreen> {
  String? _filterType;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(activityLogsProvider(widget.communityId));

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
          'Registro de Actividad',
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
        child: Column(
          children: [
            // Filter chips
            Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      isSelected: _filterType == null,
                      onTap: () => setState(() => _filterType = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Contenido Eliminado',
                      isSelected: _filterType == 'CONTENT_REMOVED',
                      onTap: () => setState(() => _filterType = 'CONTENT_REMOVED'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Reportes',
                      isSelected: _filterType == 'REPORT_RESOLVED',
                      onTap: () => setState(() => _filterType = 'REPORT_RESOLVED'),
                    ),
                  ],
                ),
              ),
            ),

            // Logs list
            Expanded(
              child: logsAsync.when(
                data: (logs) {
                  final filteredLogs = _filterType == null
                      ? logs
                      : logs.where((log) => log.actionType == _filterType).toList();

                  if (filteredLogs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay actividad',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(activityLogsProvider(widget.communityId));
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _ActivityLogItem(log: filteredLogs[index]);
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
                        'Error cargando logs',
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
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ACTIVITY LOG ITEM WIDGET (Timeline Style)
// =============================================================================

class _ActivityLogItem extends StatelessWidget {
  final ActivityLog log;

  const _ActivityLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isContentRemoval = log.isContentRemoval;
    final accentColor = _getColorForActionType(log.actionType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Content card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1F2937).withOpacity(0.6),
                    const Color(0xFF111827).withOpacity(0.7),
                  ],
                ),
                border: Border.all(
                  color: isContentRemoval
                      ? const Color(0xFFEF4444).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action type header
                  Row(
                    children: [
                      Icon(
                        _getIconForActionType(log.actionType),
                        color: accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatActionType(log.actionType),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(color: Colors.white12, height: 20),
                  
                  // Actor info
                  if (log.actorId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            'Actor:',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '@${log.actorUsername ?? "Sistema"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Target user info
                  if (log.targetUserId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            'Objetivo:',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '@${log.targetUsername ?? "Desconocido"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Timestamp
                  Text(
                    timeago.format(log.createdAt, locale: 'es'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                  
                  // Forensic viewer button for deleted content
                  if (isContentRemoval && log.deletedContent != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showForensicViewer(context, log),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Ver Contenido Original'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForActionType(String actionType) {
    switch (actionType) {
      case 'CONTENT_REMOVED':
        return const Color(0xFFEF4444); // Red
      case 'REPORT_RESOLVED':
      case 'REPORT_DISMISSED':
        return const Color(0xFFF59E0B); // Amber
      case 'GLOBAL_BAN':
      case 'USER_BANNED':
        return const Color(0xFF7C3AED); // Purple
      default:
        return const Color(0xFF0EA5E9); // Cyan
    }
  }

  IconData _getIconForActionType(String actionType) {
    switch (actionType) {
      case 'CONTENT_REMOVED':
        return Icons.delete_outline;
      case 'REPORT_RESOLVED':
        return Icons.check_circle_outline;
      case 'REPORT_DISMISSED':
        return Icons.cancel_outlined;
      case 'GLOBAL_BAN':
      case 'USER_BANNED':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  String _formatActionType(String actionType) {
    return actionType.replaceAll('_', ' ').toUpperCase();
  }

  void _showForensicViewer(BuildContext context, ActivityLog log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Contenido Eliminado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              
              const Divider(color: Colors.white24, height: 32),
              
              // Content preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.deletedContent ?? '[Sin contenido de texto]',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    
                    if (log.deletedImageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          log.deletedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white10,
                            child: const Text(
                              '[Imagen no disponible]',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Metadata
              _MetadataRow(
                label: 'Autor:',
                value: '@${log.targetUsername ?? "Desconocido"}',
              ),
              if (log.originalCreatedAt != null)
                _MetadataRow(
                  label: 'Creado:',
                  value: log.originalCreatedAt!.split('T')[0],
                ),
              if (log.deletedLikeCount != null)
                _MetadataRow(
                  label: 'Me gustas:',
                  value: '${log.deletedLikeCount}',
                ),
              if (log.deletedCommentCount != null)
                _MetadataRow(
                  label: 'Comentarios:',
                  value: '${log.deletedCommentCount}',
                ),
              
              const SizedBox(height: 16),
              
              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este contenido fue eliminado y se conserva solo con fines de auditoría',
                        style: TextStyle(
                          color: const Color(0xFFF59E0B).withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0EA5E9)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
