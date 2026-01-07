/// Project Neo - Reports Repository
///
/// Repository for managing content reports and moderation actions
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  final SupabaseClient _supabase;

  ReportsRepository(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Obtener reportes pendientes de una comunidad
  Future<List<Map<String, dynamic>>> getPendingReports({
    required String communityId,
  }) async {
    final response = await _supabase
        .from('reports')
        .select('''
          *,
          reporter:users_global!reports_reporter_id_fkey(
            id,
            username,
            avatar_global_url
          )
        ''')
        .eq('community_id', communityId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Resolver reporte con una acción
  Future<void> resolveReport({
    required String reportId,
    required String action, // 'dismiss', 'warning', 'ban'
    String? moderatorNote,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No autenticado');

    await _supabase.from('reports').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);

    print('✅ Reporte resuelto: $reportId con acción: $action');
  }

  /// Descartar reporte (no aplica)
  Future<void> dismissReport(String reportId) async {
    await resolveReport(reportId: reportId, action: 'dismiss');
  }
}
