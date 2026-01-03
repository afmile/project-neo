/// Project Neo - Profile Tabs Widget
///
/// Tab bar for profile content (Muro, Publicaciones, Actividad)
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class ProfileTabsWidget extends StatelessWidget {
  final TabController controller;

  const ProfileTabsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent, // Remove white separator line
        indicatorColor: NeoColors.accent,
        indicatorWeight: 3,
        labelColor: NeoColors.accent,
        unselectedLabelColor: NeoColors.textSecondary,
        labelStyle: NeoTextStyles.labelLarge,
        unselectedLabelStyle: NeoTextStyles.labelMedium,
        tabs: const [
          Tab(
            icon: Icon(Icons.chat_bubble_outline, size: 20),
            text: 'Muro',
          ),
          Tab(
            icon: Icon(Icons.article_outlined, size: 20),
            text: 'Publicaciones',
          ),
          Tab(
            icon: Icon(Icons.history, size: 20),
            text: 'Actividad',
          ),
        ],
      ),
    );
  }
}
