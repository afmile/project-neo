/// Project Neo - Async Value Handler
///
/// Riverpod helper extension for handling AsyncValue states with error UI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_error_view.dart';

extension AsyncValueHandler on AsyncValue {
  /// Handle AsyncValue with automatic error boundary UI
  /// 
  /// Usage:
  /// ```dart
  /// asyncValue.when(
  ///   data: (data) => DataWidget(data),
  ///   loading: () => LoadingWidget(),
  ///   error: (error, stack) => asyncValue.errorView(
  ///     message: 'Failed to load data',
  ///     onRetry: () => ref.refresh(provider),
  ///   ),
  /// );
  /// ```
  Widget errorView({
    String? message,
    VoidCallback? onRetry,
    String? route,
    String? communityId,
    String? feature,
  }) {
    return when(
      data: (_) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => AppErrorView(
        message: message ?? _getErrorMessage(error),
        onRetry: onRetry,
        route: route,
        communityId: communityId,
        feature: feature,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
  
  String _getErrorMessage(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'Ocurrió un error inesperado';
  }
}
