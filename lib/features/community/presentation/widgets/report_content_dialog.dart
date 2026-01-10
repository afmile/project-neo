/// Project Neo - Report Content Dialog
///
/// Dialog for users to report inappropriate content
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/community_moderation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider
final moderationRepositoryProvider = Provider<CommunityModerationRepository>((ref) {
  return CommunityModerationRepositoryImpl(Supabase.instance.client);
});

class ReportContentDialog extends ConsumerStatefulWidget {
  final String communityId;
  final String accusedId;
  final String? postId;
  final String? commentId;

  const ReportContentDialog({
    super.key,
    required this.communityId,
    required this.accusedId,
    this.postId,
    this.commentId,
  });

  @override
  ConsumerState<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends ConsumerState<ReportContentDialog> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _reasons = [
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'hate_speech', 'label': 'Discurso de odio'},
    {'value': 'harassment', 'label': 'Acoso'},
    {'value': 'violence', 'label': 'Violencia'},
    {'value': 'nudity', 'label': 'Contenido sexual'},
    {'value': 'other', 'label': 'Otro'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un motivo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repository = ref.read(moderationRepositoryProvider);
    final result = await repository.createUserReport(
      communityId: widget.communityId,
      accusedId: widget.accusedId,
      postId: widget.postId,
      commentId: widget.commentId,
      reason: _selectedReason!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.message}')),
        );
      },
      (_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gracias. Hemos recibido tu reporte.'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reportar Contenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Question
            Text(
              '¿Por qué lo reportas?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Reason radio buttons
            ..._reasons.map((reason) => RadioListTile<String>(
              value: reason['value']!,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() => _selectedReason = value);
              },
              title: Text(
                reason['label']!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              activeColor: const Color(0xFF3B82F6),
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            
            const SizedBox(height: 16),
            
            // Optional description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Descripción adicional (opcional)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
