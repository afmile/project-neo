/// Project Neo - Role Badge Widget
///
/// Compact badge to display user roles inline with username
/// Used in posts, comments, chat, and member lists
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

/// Badge compacto para mostrar roles de usuario
/// Se usa inline junto al username en posts, comentarios, chat, etc.
class RoleBadge extends StatelessWidget {
  final bool isFounder;
  final bool isLeader;
  final bool isModerator;
  final RoleBadgeSize size;

  const RoleBadge({
    super.key,
    this.isFounder = false,
    this.isLeader = false,
    this.isModerator = false,
    this.size = RoleBadgeSize.small,
  });

  /// Factory constructor from role flags
  factory RoleBadge.fromFlags({
    bool? isFounder,
    bool? isLeader,
    bool? isModerator,
    RoleBadgeSize size = RoleBadgeSize.small,
  }) {
    return RoleBadge(
      isFounder: isFounder ?? false,
      isLeader: isLeader ?? false,
      isModerator: isModerator ?? false,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prioridad: Founder > Leader > Moderator
    if (!isFounder && !isLeader && !isModerator) {
      return const SizedBox.shrink();
    }

    String text;
    Color backgroundColor;
    Color textColor;

    if (isFounder) {
      text = 'FUNDADOR';
      backgroundColor = const Color(0xFFF59E0B); // Amber/Dorado
      textColor = Colors.black;
    } else if (isLeader) {
      text = 'LÍDER';
      backgroundColor = NeoColors.accent; // Lila de la app
      textColor = Colors.white;
    } else {
      text = 'MOD';
      backgroundColor = const Color(0xFF10B981); // Verde esmeralda
      textColor = Colors.white;
    }

    final double fontSize = size == RoleBadgeSize.small ? 9 : 11;
    final EdgeInsets padding = size == RoleBadgeSize.small
        ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 3);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

enum RoleBadgeSize {
  small, // Para posts, comentarios, chat
  medium, // Para perfiles, members list
}
