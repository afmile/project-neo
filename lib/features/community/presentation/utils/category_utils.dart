/// Project Neo - Category Utilities
///
/// Helper utilities for mapping category IDs to display names and colors.
library;

import 'package:flutter/material.dart';

/// Category data class
class CategoryInfo {
  final String id;
  final String name;
  final Color color;
  final String emoji;

  const CategoryInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.emoji,
  });
}

/// Predefined categories with colors and emojis
class CategoryUtils {
  static const Map<String, CategoryInfo> _categories = {
    'anime': CategoryInfo(
      id: 'anime',
      name: 'Anime',
      color: Color(0xFFEF4444), // Red
      emoji: '🎌',
    ),
    'rpg': CategoryInfo(
      id: 'rpg',
      name: 'RPG',
      color: Color(0xFF3B82F6), // Blue
      emoji: '🎲',
    ),
    'gaming': CategoryInfo(
      id: 'gaming',
      name: 'Gaming',
      color: Color(0xFF8B5CF6), // Purple
      emoji: '🎮',
    ),
    'art': CategoryInfo(
      id: 'art',
      name: 'Arte',
      color: Color(0xFFEC4899), // Pink
      emoji: '🎨',
    ),
    'music': CategoryInfo(
      id: 'music',
      name: 'Música',
      color: Color(0xFF10B981), // Green
      emoji: '🎵',
    ),
    'tech': CategoryInfo(
      id: 'tech',
      name: 'Tecnología',
      color: Color(0xFF06B6D4), // Cyan
      emoji: '💻',
    ),
    'sports': CategoryInfo(
      id: 'sports',
      name: 'Deportes',
      color: Color(0xFFF59E0B), // Amber
      emoji: '⚽',
    ),
    'movies': CategoryInfo(
      id: 'movies',
      name: 'Películas',
      color: Color(0xFF6366F1), // Indigo
      emoji: '🎬',
    ),
    'books': CategoryInfo(
      id: 'books',
      name: 'Libros',
      color: Color(0xFF84CC16), // Lime
      emoji: '📚',
    ),
    'food': CategoryInfo(
      id: 'food',
      name: 'Comida',
      color: Color(0xFFF97316), // Orange
      emoji: '🍕',
    ),
  };

  /// Get category info by ID
  static CategoryInfo? getCategoryInfo(String id) {
    return _categories[id.toLowerCase()];
  }

  /// Get category name by ID (fallback to ID if not found)
  static String getCategoryName(String id) {
    return _categories[id.toLowerCase()]?.name ?? id;
  }

  /// Get category color by ID (fallback to default purple)
  static Color getCategoryColor(String id) {
    return _categories[id.toLowerCase()]?.color ?? const Color(0xFF8B5CF6);
  }

  /// Get category emoji by ID (fallback to default)
  static String getCategoryEmoji(String id) {
    return _categories[id.toLowerCase()]?.emoji ?? '🏷️';
  }

  /// Get all available categories
  static List<CategoryInfo> getAllCategories() {
    return _categories.values.toList();
  }
}
