/// Project Neo - Bug Report Provider
///
/// Riverpod provider for bug report submission state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bug_report_repository.dart';

// Provider for bug report repository
final bugReportRepositoryProvider = Provider<BugReportRepository>((ref) {
  return BugReportRepository();
});

// State notifier for bug report submission
class BugReportState {
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  
  const BugReportState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });
  
  BugReportState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return BugReportState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class BugReportNotifier extends StateNotifier<BugReportState> {
  final BugReportRepository repository;
  
  BugReportNotifier(this.repository) : super(const BugReportState());
  
  Future<void> submitReport({
    required String description,
    required String route,
    String? communityId,
    String? feature,
    String? sentryEventId,
    Map<String, dynamic>? extraData,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    
    final result = await repository.submitBugReport(
      description: description,
      route: route,
      communityId: communityId,
      feature: feature,
      sentryEventId: sentryEventId,
      extraData: extraData,
    );
    
    result.fold(
      (error) {
        state = state.copyWith(
          isSubmitting: false,
          isSuccess: false,
          errorMessage: error,
        );
      },
      (sentryEventId) {
        state = state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          errorMessage: null,
        );
      },
    );
  }
  
  void reset() {
    state = const BugReportState();
  }
}

final bugReportProvider = StateNotifierProvider<BugReportNotifier, BugReportState>((ref) {
  final repository = ref.watch(bugReportRepositoryProvider);
  return BugReportNotifier(repository);
});
