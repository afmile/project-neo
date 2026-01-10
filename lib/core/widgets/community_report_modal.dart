/// Project Neo - Community Report Modal
///
/// Modal bottom sheet for reporting community content (posts/comments)
/// Submits to the community_reports table
library;

import 'package:flutter/material.dart';
import '../theme/neo_theme.dart';
import '../../features/community/data/repositories/reports_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Report reason with display label and DB value
class _ReportReason {
  final String label;
  final String value;
  
  const _ReportReason(this.label, this.value);
}

/// List of report reasons (Spanish labels, DB enum values)
const List<_ReportReason> _reportReasons = [
  _ReportReason('Spam o no deseado', 'spam'),
  _ReportReason('Acoso o incitación al odio', 'harassment'),
  _ReportReason('Contenido sexual o violento', 'violence'),
  _ReportReason('Información falsa', 'misinformation'),
  _ReportReason('Otro', 'other'),
];

/// Shows a bottom sheet modal for reporting community content
Future<void> showCommunityReportModal({
  required BuildContext context,
  required String communityId,
  required String accusedId,
  String? postId,
  String? commentId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) => _CommunityReportModalContent(
      communityId: communityId,
      accusedId: accusedId,
      postId: postId,
      commentId: commentId,
    ),
  );
}

class _CommunityReportModalContent extends StatefulWidget {
  final String communityId;
  final String accusedId;
  final String? postId;
  final String? commentId;

  const _CommunityReportModalContent({
    required this.communityId,
    required this.accusedId,
    this.postId,
    this.commentId,
  });

  @override
  State<_CommunityReportModalContent> createState() => _CommunityReportModalContentState();
}

class _CommunityReportModalContentState extends State<_CommunityReportModalContent> {
  bool _isSubmitting = false;

  Future<void> _submitReport(String reasonValue) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final repository = ReportsRepository(supabase);

      await repository.createCommunityReport(
        communityId: widget.communityId,
        accusedId: widget.accusedId,
        postId: widget.postId,
        commentId: widget.commentId,
        reason: reasonValue,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gracias. Hemos recibido tu reporte y lo revisaremos.'),
            backgroundColor: NeoColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting community report: $e');
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
              'Reportar Contenido',
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
              itemCount: _reportReasons.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.grey.withValues(alpha: 0.3),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final reason = _reportReasons[index];
                return ListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: Colors.red[400],
                  ),
                  title: Text(
                    reason.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: () => _submitReport(reason.value),
                );
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
