/// Project Neo - Notification Bell Widget
///
/// AppBar icon with unread count badge for community notifications
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/notifications_provider.dart';
import '../screens/community_notifications_screen.dart';

class NotificationBellWidget extends ConsumerWidget {
  final String communityId;
  final Color iconColor;

  const NotificationBellWidget({
    super.key,
    required this.communityId,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationsCountProvider(communityId));

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: iconColor,
          ),
          // Unread badge
          unreadAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              
              return Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: NeoColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      tooltip: 'Notificaciones',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CommunityNotificationsScreen(
              communityId: communityId,
            ),
          ),
        );
      },
    );
  }
}
