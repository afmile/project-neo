import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/community_user_list_widget.dart';

// Re-export UserListType
export '../widgets/community_user_list_widget.dart' show UserListType;

class CommunityUsersListScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String userId;
  final UserListType type;

  const CommunityUsersListScreen({
    super.key,
    required this.communityId,
    required this.userId,
    required this.type,
  });

  @override
  ConsumerState<CommunityUsersListScreen> createState() => _CommunityUsersListScreenState();
}

class _CommunityUsersListScreenState extends ConsumerState<CommunityUsersListScreen> {
  
  String get _title {
    switch (widget.type) {
      case UserListType.friends:
        return 'Amistades';
      case UserListType.followers:
        return 'Seguidores';
      case UserListType.following:
        return 'Siguiendo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: CommunityUserListWidget(
        communityId: widget.communityId,
        userId: widget.userId,
        type: widget.type,
      ),
    );
  }
}
