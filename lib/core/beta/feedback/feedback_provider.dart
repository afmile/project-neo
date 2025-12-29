/// Project Neo - Feedback Provider
///
/// Riverpod state management for feedback submission.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'feedback_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Feedback repository provider
final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(Supabase.instance.client);
});

/// Feedback submission state
enum FeedbackSubmitState {
  idle,
  submitting,
  success,
  error,
}

/// Feedback notifier for managing submission state
class FeedbackNotifier extends StateNotifier<FeedbackSubmitState> {
  final FeedbackRepository _repository;
  final String? _userId;
  String? lastError;
  
  FeedbackNotifier(this._repository, this._userId) : super(FeedbackSubmitState.idle);
  
  /// Submit feedback
  Future<bool> submit({
    required FeedbackType type,
    required String message,
    required String currentRoute,
  }) async {
    if (_userId == null) {
      lastError = 'Usuario no autenticado';
      state = FeedbackSubmitState.error;
      return false;
    }
    
    if (message.trim().isEmpty) {
      lastError = 'El mensaje no puede estar vacío';
      state = FeedbackSubmitState.error;
      return false;
    }
    
    state = FeedbackSubmitState.submitting;
    
    try {
      await _repository.submitFeedback(
        userId: _userId,
        type: type,
        message: message.trim(),
        context: _repository.createContext(currentRoute),
      );
      
      state = FeedbackSubmitState.success;
      return true;
    } catch (e) {
      lastError = 'Error al enviar: ${e.toString()}';
      state = FeedbackSubmitState.error;
      return false;
    }
  }
  
  /// Reset to idle state
  void reset() {
    state = FeedbackSubmitState.idle;
    lastError = null;
  }
}

/// Feedback notifier provider
final feedbackNotifierProvider = StateNotifierProvider<FeedbackNotifier, FeedbackSubmitState>((ref) {
  final repository = ref.watch(feedbackRepositoryProvider);
  final userId = ref.watch(authProvider).user?.id;
  return FeedbackNotifier(repository, userId);
});
