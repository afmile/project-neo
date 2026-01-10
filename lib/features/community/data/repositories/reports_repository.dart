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

  /// Create a community-scoped content report
  /// Submits to the community_reports table for moderation
  Future<void> createCommunityReport({
    required String communityId,
    required String accusedId,
    required String reason,
    String? postId,
    String? commentId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No autenticado');

    // Validate that at least one target is provided
    if (postId == null && commentId == null) {
      throw Exception('Debe especificar un post o comentario a reportar');
    }

    await _supabase.from('community_reports').insert({
      'community_id': communityId,
      'reporter_id': userId,
      'accused_id': accusedId,
      'post_id': postId,
      'comment_id': commentId,
      'reason': reason,
      'status': 'pending',
    });

    print('🚩 Reporte de comunidad creado: $reason');
  }
}
