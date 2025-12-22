/// Project Neo - User Title Tag Entity
///
/// Represents a custom title/badge awarded to users by community leaders
library;

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class UserTitleTag extends Equatable {
  /// Display text (supports emojis and special characters)
  final String text;
  
  /// Background color of the pill
  final Color backgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Order for display (lower = first)
  final int displayOrder;

  const UserTitleTag({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.displayOrder = 0,
  });

  @override
  List<Object?> get props => [text, backgroundColor, textColor, displayOrder];
}
