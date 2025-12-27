/// Project Neo - User Tag Model
///
/// Data model for converting Supabase user_tags to UserTitleTag entity
library;

import 'package:flutter/material.dart';
import '../../domain/entities/user_title_tag.dart';

class UserTagModel {
  /// Convert from Supabase JSON to UserTitleTag entity
  static UserTitleTag fromSupabase(Map<String, dynamic> json) {
    return UserTitleTag(
      text: json['tag_text'] as String,
      backgroundColor: Color(int.parse(json['bg_color'] as String, radix: 16)),
      textColor: Color(int.parse(json['text_color'] as String, radix: 16)),
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  /// Convert list from Supabase
  static List<UserTitleTag> listFromSupabase(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromSupabase(json as Map<String, dynamic>))
        .toList();
  }
}
