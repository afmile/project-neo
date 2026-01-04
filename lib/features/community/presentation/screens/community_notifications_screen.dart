/// Project Neo - Community Notifications Screen
///
/// Displays the notification inbox for a community
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_tile.dart';

class CommunityNotificationsScreen extends ConsumerWidget {
  final String communityId;

  const CommunityNotificationsScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(communityNotificationsProvider(communityId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notificaciones',
          style: NeoTextStyles.headlineMedium,
        ),
        actions: [
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all, color: NeoColors.textSecondary),
            tooltip: 'Marcar todo como leído',
            onPressed: () async {
              final count = await ref
                  .read(notificationActionsProvider(communityId).notifier)
                  .markAllAsRead();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count notificaciones marcadas como leídas'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
        error: (error, _) => _buildErrorState(context, ref),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            color: NeoColors.accent,
            backgroundColor: NeoColors.card,
            onRefresh: () async {
              ref.invalidate(communityNotificationsProvider(communityId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: NeoColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: NeoTextStyles.headlineSmall.copyWith(
              color: NeoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando recibas notificaciones\naparecerán aquí',
            textAlign: TextAlign.center,
            style: NeoTextStyles.bodySmall.copyWith(
              color: NeoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: NeoColors.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar notificaciones',
            style: NeoTextStyles.bodyLarge.copyWith(color: NeoColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(communityNotificationsProvider(communityId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, notification) {
    // Future: Navigate to entity (profile, post, etc.)
    // For now, just mark as read (handled in tile)
  }
}
