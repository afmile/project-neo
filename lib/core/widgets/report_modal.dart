/// Project Neo - Report Modal
///
/// Reusable modal for reporting content (posts, comments, users, chats)
/// Shows predefined Spanish reasons and submits to Supabase
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/neo_theme.dart';

/// List of valid report reasons (must match DB constraint)
const List<String> reportReasons = [
  'Simplemente no me gusta',
  'Bullying o contacto no deseado',
  'Suicidio, autolesión o trastornos alimentarios',
  'Violencia, odio o explotación',
  'Venta o promoción de artículos restringidos',
  'Desnudos o actividad sexual',
  'Estafa, fraude o spam',
  'Información falsa',
  'Propiedad intelectual',
];

/// Shows a bottom sheet modal for reporting content
Future<void> showReportModal({
  required BuildContext context,
  required String targetType, // 'post', 'comment', 'chat', 'user'
  required String targetId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) => _ReportModalContent(
      targetType: targetType,
      targetId: targetId,
    ),
  );
}

class _ReportModalContent extends StatefulWidget {
  final String targetType;
  final String targetId;

  const _ReportModalContent({
    required this.targetType,
    required this.targetId,
  });

  @override
  State<_ReportModalContent> createState() => _ReportModalContentState();
}

class _ReportModalContentState extends State<_ReportModalContent> {
  bool _isSubmitting = false;

  Future<void> _submitReport(String reason) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await supabase.from('reports').insert({
        'reporter_id': userId,
        'target_type': widget.targetType,
        'target_id': widget.targetId,
        'reason': reason,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gracias por informarnos'),
            backgroundColor: NeoColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Reportar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Reasons list
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: NeoColors.accent),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reportReasons.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.grey.withValues(alpha: 0.3),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final reason = reportReasons[index];
                return ListTile(
                  title: Text(
                    reason,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: () => _submitReport(reason),
                );
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
