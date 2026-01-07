/// Project Neo - Reports Provider
///
/// Riverpod providers for report management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/reports_repository.dart';

/// Repository provider
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(Supabase.instance.client);
});

/// Provider for pending reports in a community
final pendingReportsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, communityId) async {
    final repo = ref.watch(reportsRepositoryProvider);
    return repo.getPendingReports(communityId: communityId);
  },
);

/// Count of pending reports for badge display
final pendingReportsCountProvider = FutureProvider.family<int, String>(
  (ref, communityId) async {
    final reports = await ref.watch(pendingReportsProvider(communityId).future);
    return reports.length;
  },
);
