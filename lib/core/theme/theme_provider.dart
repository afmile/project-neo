/// Project Neo - Theme Provider
///
/// Riverpod provider for dynamic theme with community accent colors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'neo_theme.dart';

/// Provider for the current accent color
/// Can be changed per-community
final accentColorProvider = StateProvider<Color>((ref) {
  return NeoColors.accent; // Default Discord-like blue
});

/// Provider for the complete theme data
final themeProvider = Provider<ThemeData>((ref) {
  final accentColor = ref.watch(accentColorProvider);
  return NeoTheme.darkTheme(accentColor: accentColor);
});

/// Predefined community accent colors
class CommunityAccents {
  CommunityAccents._();
  
  static const Color discordBlue = Color(0xFF5865F2);
  static const Color twitchPurple = Color(0xFF9146FF);
  static const Color youtubeRed = Color(0xFFFF0000);
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color twitterBlue = Color(0xFF1DA1F2);
  static const Color instagramPink = Color(0xFFE1306C);
  static const Color telegramBlue = Color(0xFF0088CC);
  static const Color slackPurple = Color(0xFF4A154B);
  
  /// Get accent color by name
  static Color? fromName(String name) {
    switch (name.toLowerCase()) {
      case 'discord': return discordBlue;
      case 'twitch': return twitchPurple;
      case 'youtube': return youtubeRed;
      case 'spotify': return spotifyGreen;
      case 'twitter': return twitterBlue;
      case 'instagram': return instagramPink;
      case 'telegram': return telegramBlue;
      case 'slack': return slackPurple;
      default: return null;
    }
  }
  
  /// Parse hex color string
  static Color? fromHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }
}
