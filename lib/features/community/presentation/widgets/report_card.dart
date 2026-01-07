/// Project Neo - Report Card Widget
///
/// Widget to display a single report in the moderation panel
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../providers/reports_provider.dart';

class ReportCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;
  final String communityId;
  final VoidCallback onResolved;

  const ReportCard({
    super.key,
    required this.report,
    required this.communityId,
    required this.onResolved,
  });

  @override
  ConsumerState<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<ReportCard> {
  bool _isProcessing = false;

  Future<void> _resolveReport(String action) async {
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(reportsRepositoryProvider);
      await repo.resolveReport(
        reportId: widget.report['id'],
        action: action,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reporte ${_getActionName(action)}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onResolved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _getActionName(String action) {
    switch (action) {
      case 'dismiss':
        return 'descartado';
      case 'warning':
        return 'advertido';
      case 'ban':
        return 'usuario baneado';
      default:
        return 'resuelto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reporter = widget.report['reporter'] as Map<String, dynamic>?;
    final targetType = widget.report['target_type'] as String;
    final reason = widget.report['reason'] as String;
    final createdAt = DateTime.parse(widget.report['created_at'] as String);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Reporter + Time
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: NeoColors.accent.withOpacity(0.2),
                backgroundImage: reporter?['avatar_global_url'] != null
                    ? NetworkImage(reporter!['avatar_global_url'])
                    : null,
                child: reporter?['avatar_global_url'] == null
                    ? Text(
                        (reporter?['username'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: NeoColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reporter?['username'] ?? 'Usuario',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      timeago.format(createdAt, locale: 'es'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              _TargetTypeBadge(targetType: targetType),
            ],
          ),
          
          const SizedBox(height: 12),
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 12),
          
          // Reason
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Actions
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConfirmDialog('dismiss'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Descartar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog('warning'),
                    icon: const Icon(Icons.warning_amber, size: 18),
                    label: const Text('Advertir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog('ban'),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Ban'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Confirmar: ${_getActionName(action)}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres ${_getActionName(action)} este reporte?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resolveReport(action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'ban' ? Colors.red : null,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _TargetTypeBadge extends StatelessWidget {
  final String targetType;

  const _TargetTypeBadge({required this.targetType});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (targetType) {
      case 'post':
        icon = Icons.article;
        color = Colors.blue;
        label = 'Post';
        break;
      case 'comment':
        icon = Icons.comment;
        color = Colors.green;
        label = 'Comentario';
        break;
      case 'user':
        icon = Icons.person;
        color = Colors.purple;
        label = 'Usuario';
        break;
      case 'chat':
        icon = Icons.message;
        color = Colors.orange;
        label = 'Chat';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        label = 'Otro';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
