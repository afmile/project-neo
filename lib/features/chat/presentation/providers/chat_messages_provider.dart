import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../data/repositories/chat_message_repository.dart';

/// Provider for chat message repository
final chatMessageRepositoryProvider = Provider<ChatMessageRepository>((ref) {
  return ChatMessageRepository();
});

/// Stream provider for messages in a specific channel
final chatMessagesStreamProvider =
    StreamProvider.family<List<ChatMessageEntity>, String>((ref, channelId) {
  final repository = ref.watch(chatMessageRepositoryProvider);
  return repository.getMessagesStream(channelId);
});

/// Provider for sending messages
final sendMessageProvider = Provider<ChatMessageRepository>((ref) {
  return ref.watch(chatMessageRepositoryProvider);
});
