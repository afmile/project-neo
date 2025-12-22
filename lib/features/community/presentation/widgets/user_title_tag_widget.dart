/// Project Neo - User Title Tag Widget
///
/// Displays a custom pill-shaped badge for user titles
library;

import 'package:flutter/material.dart';
import '../../domain/entities/user_title_tag.dart';

class UserTitleTagWidget extends StatelessWidget {
  final UserTitleTag tag;

  const UserTitleTagWidget({
    super.key,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tag.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tag.backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        tag.text,
        style: TextStyle(
          color: tag.textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
