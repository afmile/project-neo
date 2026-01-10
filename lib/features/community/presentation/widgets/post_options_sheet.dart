/// Project Neo - Post Options Bottom Sheet
///
/// Dark premium design modal sheet for post actions
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/community_report_modal.dart';

/// Shows a bottom sheet with post options
///
/// Displays options: Share, Copy text, Block account, Report
/// [communityId], [authorId], [postId], [commentId] are used for reporting
/// [currentUserId] is used to hide "Reportar" if user is the author
void showPostOptionsSheet(
  BuildContext context, {
  required String content,
  bool showDelete = false,
  VoidCallback? onDelete,
  // Report parameters
  String? communityId,
  String? authorId,
  String? postId,
  String? commentId,
  String? currentUserId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PostOptionsSheet(
      content: content,
      showDelete: showDelete,
      onDelete: onDelete,
      communityId: communityId,
      authorId: authorId,
      postId: postId,
      commentId: commentId,
      currentUserId: currentUserId,
    ),
  );
}


class _PostOptionsSheet extends StatelessWidget {
  final String content;
  final bool showDelete;
  final VoidCallback? onDelete;
  // Report parameters
  final String? communityId;
  final String? authorId;
  final String? postId;
  final String? commentId;
  final String? currentUserId;

  const _PostOptionsSheet({
    required this.content,
    this.showDelete = false,
    this.onDelete,
    this.communityId,
    this.authorId,
    this.postId,
    this.commentId,
    this.currentUserId,
  });

  /// Check if report option should be shown
  /// Hide if user is the author or if missing required data
  bool get _canShowReport {
    // Don't show report if user is author
    if (currentUserId != null && authorId != null && currentUserId == authorId) {
      return false;
    }
    // Need communityId and authorId to submit report
    return communityId != null && authorId != null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C2229), // Dark Grey
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Header: Title + Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'More options',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Menu items (top to bottom order)
          _buildMenuItem(
            context: context,
            icon: Icons.ios_share,
            label: 'Compartir',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement share functionality
            },
          ),
          
          _buildMenuItem(
            context: context,
            icon: Icons.content_copy,
            label: 'Copiar texto',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado al portapapeles')),
                );
              }
            },
          ),
          
          _buildMenuItem(
            context: context,
            icon: Icons.block,
            label: 'Bloquear cuenta',
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement block account functionality
            },
          ),
          
          // Delete item (if author)
          if (showDelete && onDelete != null)
            _buildMenuItem(
              context: context,
              icon: Icons.delete_outline,
              label: 'Eliminar',
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop();
                onDelete!();
              },
            ),
          
          // Report item (hide if user is author)
          if (_canShowReport)
            _buildMenuItem(
              context: context,
              icon: Icons.flag_outlined,
              label: 'Reportar',
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop();
                showCommunityReportModal(
                  context: context,
                  communityId: communityId!,
                  accusedId: authorId!,
                  postId: postId,
                  commentId: commentId,
                );
              },
            ),

          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? Colors.red[400]! : Colors.white;
    final textColor = isDestructive ? Colors.red[400]! : Colors.white;
    final backgroundColor = isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Label
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
