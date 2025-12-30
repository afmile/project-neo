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
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: NeoColors.border,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: NeoColors.accent,
            width: 2,
          ),
        ),
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
