/// Project Neo - Community Title Model
///
/// Represents a custom title that can be assigned to users in a community
library;

import 'package:flutter/material.dart';

class CommunityTitle {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final int priority;

  const CommunityTitle({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.priority,
  });

  /// Parse color from hex string (#RRGGBB or #AARRGGBB)
  static Color parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      
      // Remove # if present
      String hex = hexString.replaceFirst('#', '');
      
      // Add alpha if not present
      if (hex.length == 6) {
        buffer.write('ff'); // Full opacity
      }
      
      buffer.write(hex);
      
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      // Fallback to gray if parsing fails
      return Colors.grey;
    }
  }

  /// Factory from JSON (Supabase response)
  factory CommunityTitle.fromJson(Map<String, dynamic> json) {
    return CommunityTitle(
      text: json['text'] as String,
      textColor: parseColor(json['text_color'] as String),
      backgroundColor: parseColor(json['background_color'] as String),
      priority: json['priority'] as int,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'text_color': '#${textColor.value.toRadixString(16).padLeft(8, '0')}',
      'background_color': '#${backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
      'priority': priority,
    };
  }

  @override
  String toString() {
    return 'CommunityTitle(text: $text, priority: $priority)';
  }
}
