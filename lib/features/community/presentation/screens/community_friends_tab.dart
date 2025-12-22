/// Project Neo - Community Friends Tab
///
/// Shows online friends and their activity feed
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/friend_presence.dart';
import '../../domain/entities/activity_event.dart';
import '../widgets/friend_presence_avatar.dart';
import '../widgets/activity_event_card.dart';

class CommunityFriendsTab extends StatefulWidget {
  final String communityId;

  const CommunityFriendsTab({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityFriendsTab> createState() => _CommunityFriendsTabState();
}

class _CommunityFriendsTabState extends State<CommunityFriendsTab> {
  late List<FriendPresence> _onlineFriends;
  late List<ActivityEvent> _activityEvents;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    // Mock online friends
    _onlineFriends = [
      const FriendPresence(
        userId: 'user_1',
        username: 'Ana García',
        isOnline: true,
        location: PresenceLocation.voiceChat,
        locationDetail: 'Sala General',
      ),
      const FriendPresence(
        userId: 'user_2',
        username: 'Carlos Ruiz',
        isOnline: true,
        location: PresenceLocation.reading,
        locationDetail: 'Blog: Flutter Tips',
      ),
      const FriendPresence(
        userId: 'user_3',
        username: 'María López',
        isOnline: true,
        location: PresenceLocation.quiz,
        locationDetail: 'Quiz de Dart',
      ),
      const FriendPresence(
        userId: 'user_4',
        username: 'Pedro Sánchez',
        isOnline: true,
        location: PresenceLocation.browsing,
      ),
      const FriendPresence(
        userId: 'user_5',
        username: 'Laura Martínez',
        isOnline: true,
        location: PresenceLocation.voiceChat,
        locationDetail: 'Sala de Ayuda',
      ),
      const FriendPresence(
        userId: 'user_6',
        username: 'Diego Torres',
        isOnline: true,
        location: PresenceLocation.reading,
        locationDetail: 'Wiki: Arquitectura',
      ),
    ];

    // Mock activity events
    _activityEvents = [
      ActivityEvent(
        id: 'evt_1',
        userId: 'user_1',
        username: 'Ana García',
        type: ActivityType.newBlog,
        title: 'Guía Completa de Riverpod',
        subtitle: 'State Management en Flutter',
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      ActivityEvent(
        id: 'evt_2',
        userId: 'user_2',
        username: 'Carlos Ruiz',
        type: ActivityType.levelUp,
        title: 'Nivel 7',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityEvent(
        id: 'evt_3',
        userId: 'user_3',
        username: 'María López',
        type: ActivityType.newComment,
        title: 'Encuesta: Frameworks Favoritos',
        subtitle: '"Me encanta Flutter!"',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      ActivityEvent(
        id: 'evt_4',
        userId: 'user_4',
        username: 'Pedro Sánchez',
        type: ActivityType.newQuiz,
        title: 'Quiz: Conoces Dart?',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ActivityEvent(
        id: 'evt_5',
        userId: 'user_5',
        username: 'Laura Martínez',
        type: ActivityType.completedQuiz,
        title: 'Flutter Basics',
        subtitle: 'Puntuación: 95/100',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      ActivityEvent(
        id: 'evt_6',
        userId: 'user_6',
        username: 'Diego Torres',
        type: ActivityType.newWiki,
        title: 'Arquitectura Clean en Flutter',
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      ActivityEvent(
        id: 'evt_7',
        userId: 'user_1',
        username: 'Ana García',
        type: ActivityType.newComment,
        title: 'Blog: Widgets Personalizados',
        subtitle: '"Excelente tutorial!"',
        timestamp: now.subtract(const Duration(hours: 10)),
      ),
      ActivityEvent(
        id: 'evt_8',
        userId: 'user_2',
        username: 'Carlos Ruiz',
        type: ActivityType.newBlog,
        title: 'Animaciones Avanzadas',
        timestamp: now.subtract(const Duration(hours: 12)),
      ),
      ActivityEvent(
        id: 'evt_9',
        userId: 'user_3',
        username: 'María López',
        type: ActivityType.levelUp,
        title: 'Nivel 5',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityEvent(
        id: 'evt_10',
        userId: 'user_4',
        username: 'Pedro Sánchez',
        type: ActivityType.newBlog,
        title: 'Testing en Flutter',
        subtitle: 'Unit, Widget y Integration Tests',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      ActivityEvent(
        id: 'evt_11',
        userId: 'user_5',
        username: 'Laura Martínez',
        type: ActivityType.newWiki,
        title: 'Guía de Widgets',
        timestamp: now.subtract(const Duration(days: 1, hours: 8)),
      ),
      ActivityEvent(
        id: 'evt_12',
        userId: 'user_6',
        username: 'Diego Torres',
        type: ActivityType.completedQuiz,
        title: 'Advanced Dart',
        subtitle: 'Puntuación: 88/100',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      ActivityEvent(
        id: 'evt_13',
        userId: 'user_1',
        username: 'Ana García',
        type: ActivityType.newComment,
        title: 'Quiz: Flutter Widgets',
        subtitle: '"Muy útil!"',
        timestamp: now.subtract(const Duration(days: 2, hours: 5)),
      ),
      ActivityEvent(
        id: 'evt_14',
        userId: 'user_2',
        username: 'Carlos Ruiz',
        type: ActivityType.joinedCommunity,
        title: 'Flutter Devs',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      ActivityEvent(
        id: 'evt_15',
        userId: 'user_3',
        username: 'María López',
        type: ActivityType.newBlog,
        title: 'Performance Optimization',
        subtitle: 'Tips para apps más rápidas',
        timestamp: now.subtract(const Duration(days: 3, hours: 6)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Presence Grid Header
        _buildPresenceGrid(),
        
        // Divider
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        
        // Activity Feed
        Expanded(
          child: _buildActivityFeed(),
        ),
      ],
    );
  }

  Widget _buildPresenceGrid() {
    return Container(
      height: 180, // Fixed height for 2 rows
      color: Colors.grey[900],
      child: _onlineFriends.isEmpty
          ? _buildEmptyPresence()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(NeoSpacing.md),
              child: Wrap(
                direction: Axis.vertical,
                spacing: 8,
                runSpacing: 8,
                children: _onlineFriends
                    .map((friend) => FriendPresenceAvatar(
                          presence: friend,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/community-user-profile',
                              arguments: {
                                'userId': friend.userId,
                                'communityId': widget.communityId,
                              },
                            );
                          },
                        ))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildEmptyPresence() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '😴',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            'Ningún amigo conectado',
            style: NeoTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus amigos aparecerán aquí cuando estén online',
            style: NeoTextStyles.bodySmall.copyWith(
              color: NeoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    if (_activityEvents.isEmpty) {
      return _buildEmptyActivity();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: NeoSpacing.md),
      itemCount: _activityEvents.length,
      itemBuilder: (context, index) {
        final event = _activityEvents[index];
        return ActivityEventCard(
          event: event,
          isFirst: index == 0,
          isLast: index == _activityEvents.length - 1,
          onTap: () {
            // TODO: Navigate to content
          },
        );
      },
    );
  }

  Widget _buildEmptyActivity() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NeoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '📭',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay actividad reciente',
              style: NeoTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando tus amigos publiquen contenido, aparecerá aquí',
              style: NeoTextStyles.bodyMedium.copyWith(
                color: NeoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
