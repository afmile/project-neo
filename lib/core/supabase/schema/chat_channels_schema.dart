/// Supabase schema constants for chat_channels table
/// 
/// VERIFIED SCHEMA - These are the ACTUAL columns that exist in production.
/// DO NOT use string literals for column names - always use these constants.
class ChatChannelsSchema {
  ChatChannelsSchema._(); // Private constructor to prevent instantiation

  // Table name
  static const String table = 'chat_channels';

  // Column names (verified against actual DB schema)
  static const String id = 'id';
  static const String communityId = 'community_id';
  static const String ownerId = 'owner_id';  // NOT creator_id!
  static const String title = 'title';
  static const String description = 'description';
  static const String iconUrl = 'icon_url';
  static const String type = 'type';
  static const String backgroundImageUrl = 'background_image_url';
  static const String isPinned = 'is_pinned';
  static const String pinnedOrder = 'pinned_order';
  static const String voiceEnabled = 'voice_enabled';
  static const String videoEnabled = 'video_enabled';
  static const String projectionEnabled = 'projection_enabled';
  static const String createdAt = 'created_at';

  // Common select fragments
  
  /// Select for Home VIVO "Ahora mismo" section
  static const String selectNow = 
      '$id, $title, $description, $backgroundImageUrl, '
      '$isPinned, $pinnedOrder, $createdAt, $ownerId';

  /// Full select (all columns)
  static const String selectFull =
      '$id, $communityId, $ownerId, $title, $description, '
      '$iconUrl, $type, $backgroundImageUrl, $isPinned, $pinnedOrder, '
      '$voiceEnabled, $videoEnabled, $projectionEnabled, $createdAt';
}
