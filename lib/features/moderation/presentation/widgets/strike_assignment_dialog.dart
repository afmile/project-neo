/// Project Neo - Strike Assignment Dialog
///
/// Dialog for moderators to assign strikes to users
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/moderation_providers.dart';

class StrikeAssignmentDialog extends ConsumerStatefulWidget {
  final String communityId;
  final String userId;
  final String username;
  final int currentStrikeCount;
  final String? contentType;
  final String? contentId;

  const StrikeAssignmentDialog({
    super.key,
    required this.communityId,
    required this.userId,
    required this.username,
    required this.currentStrikeCount,
    this.contentType,
    this.contentId,
  });

  @override
  ConsumerState<StrikeAssignmentDialog> createState() => _StrikeAssignmentDialogState();
}

class _StrikeAssignmentDialogState extends ConsumerState<StrikeAssignmentDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _assignStrike() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(strikeAssignmentProvider.notifier);
    
    await notifier.assignStrike(
      communityId: widget.communityId,
      userId: widget.userId,
      reason: _reasonController.text.trim(),
      contentType: widget.contentType,
      contentId: widget.contentId,
    );

    final state = ref.read(strikeAssignmentProvider);
    
    if (state.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error}')),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(strikeAssignmentProvider);
    final newStrikeCount = widget.currentStrikeCount + 1;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: newStrikeCount >= 3 ? Colors.red : Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Asignar Strike',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.username,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Reason field
              Text(
                'Razón del strike',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 200,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ej: Contenido inapropiado, spam, acoso...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: newStrikeCount >= 3 ? Colors.red : Colors.amber,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Debes especificar una razón';
                  }
                  if (value.trim().length < 10) {
                    return 'La razón debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Strike count warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (newStrikeCount >= 3 ? Colors.red : Colors.amber).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (newStrikeCount >= 3 ? Colors.red : Colors.amber).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      newStrikeCount >= 3 ? Icons.error_outline : Icons.info_outline,
                      color: newStrikeCount >= 3 ? Colors.red : Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        newStrikeCount >= 3
                            ? 'Este será el strike $newStrikeCount. Se activará revisión de staff.'
                            : 'Este será el strike $newStrikeCount de 3',
                        style: TextStyle(
                          color: newStrikeCount >= 3 ? Colors.red[200] : Colors.amber[200],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: assignmentState.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: assignmentState.isLoading ? null : _assignStrike,
          style: ElevatedButton.styleFrom(
            backgroundColor: newStrikeCount >= 3 ? Colors.red : Colors.amber,
            foregroundColor: Colors.white,
          ),
          child: assignmentState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Asignar Strike'),
        ),
      ],
    );
  }
}
