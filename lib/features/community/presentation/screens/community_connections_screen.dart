import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../widgets/community_user_list_widget.dart';

class CommunityConnectionsScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String userId;
  final UserListType initialType; // followers or following

  const CommunityConnectionsScreen({
    super.key,
    required this.communityId,
    required this.userId,
    // Default to followers if friends (shouldn't happen) or something else
    this.initialType = UserListType.followers,
  });

  @override
  ConsumerState<CommunityConnectionsScreen> createState() => _CommunityConnectionsScreenState();
}

class _CommunityConnectionsScreenState extends ConsumerState<CommunityConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 0: Followers, 1: Following
    final initialIndex = widget.initialType == UserListType.following ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Conexiones', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: NeoColors.accent,
          unselectedLabelColor: NeoColors.textSecondary,
          indicatorColor: NeoColors.accent,
          tabs: const [
            Tab(text: 'Seguidores'),
            Tab(text: 'Siguiendo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CommunityUserListWidget(
            communityId: widget.communityId,
            userId: widget.userId,
            type: UserListType.followers,
          ),
          CommunityUserListWidget(
            communityId: widget.communityId,
            userId: widget.userId,
            type: UserListType.following,
          ),
        ],
      ),
    );
  }
}
