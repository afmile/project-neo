/// Project Neo - App Error View
///
/// Reusable error display widget with retry and report functionality.
/// Matches Neo's high-tech minimalist theme.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/neo_theme.dart';

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? route;
  final String? communityId;
  final String? feature;
  final Object? error;
  final StackTrace? stackTrace;
  
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.route,
    this.communityId,
    this.feature,
    this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with glassmorphism effect
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NeoColors.error.withOpacity(0.2),
                    NeoColors.error.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: NeoColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: NeoColors.error,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error title
            Text(
              'Algo salió mal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: NeoColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Error message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: NeoColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Retry button (if provided)
                if (onRetry != null) ...[
                  _ActionButton(
                    label: 'Reintentar',
                    icon: Icons.refresh,
                    onPressed: onRetry!,
                    isPrimary: true,
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Report issue button
                _ActionButton(
                  label: 'Reportar problema',
                  icon: Icons.bug_report_outlined,
                  onPressed: () => _openReportIssue(context),
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _openReportIssue(BuildContext context) {
    context.push(
      '/report-issue',
      extra: {
        'route': route,
        'community_id': communityId,
        'feature': feature,
        'error_message': message,
        'error': error?.toString(),
        'stack_trace': stackTrace?.toString(),
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NeoColors.accent,
                  NeoColors.accent.withOpacity(0.8),
                ],
              )
            : null,
        border: Border.all(
          color: isPrimary
              ? NeoColors.accent.withOpacity(0.3)
              : NeoColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary
                      ? NeoColors.background
                      : NeoColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isPrimary
                        ? NeoColors.background
                        : NeoColors.textPrimary,
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
