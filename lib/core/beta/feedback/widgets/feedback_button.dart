/// Project Neo - Feedback Button Widget
///
/// FAB or menu item that opens feedback modal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/neo_theme.dart';
import '../feedback_provider.dart';
import '../feedback_repository.dart';

/// Feedback button - can be used as FAB or anywhere in the app
class FeedbackButton extends ConsumerWidget {
  const FeedbackButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      heroTag: 'feedback_fab',
      onPressed: () => _showFeedbackModal(context, ref),
      backgroundColor: NeoColors.accent,
      icon: const Icon(Icons.feedback_outlined, color: Colors.white),
      label: const Text('Feedback', style: TextStyle(color: Colors.white)),
    );
  }
  
  void _showFeedbackModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackModal(
        currentRoute: GoRouterState.of(context).matchedLocation,
      ),
    );
  }
}

/// Feedback modal content
class _FeedbackModal extends ConsumerStatefulWidget {
  final String currentRoute;
  
  const _FeedbackModal({required this.currentRoute});

  @override
  ConsumerState<_FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends ConsumerState<_FeedbackModal> {
  FeedbackType _selectedType = FeedbackType.suggestion;
  final _messageController = TextEditingController();
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(feedbackNotifierProvider);
    
    // Listen for success
    ref.listen<FeedbackSubmitState>(feedbackNotifierProvider, (prev, next) {
      if (next == FeedbackSubmitState.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Gracias por tu feedback!'),
            backgroundColor: NeoColors.success,
          ),
        );
        ref.read(feedbackNotifierProvider.notifier).reset();
      }
    });
    
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.15,
      ),
      decoration: const BoxDecoration(
        color: NeoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NeoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Enviar Feedback',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NeoColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Tu opinión nos ayuda a mejorar',
                style: TextStyle(color: NeoColors.textSecondary),
              ),
              
              const SizedBox(height: 24),
              
              // Type selector
              const Text(
                'Tipo de feedback',
                style: TextStyle(
                  color: NeoColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  _TypeChip(
                    label: '🐛 Bug',
                    selected: _selectedType == FeedbackType.bug,
                    onTap: () => setState(() => _selectedType = FeedbackType.bug),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: '💡 Sugerencia',
                    selected: _selectedType == FeedbackType.suggestion,
                    onTap: () => setState(() => _selectedType = FeedbackType.suggestion),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: '💬 Otro',
                    selected: _selectedType == FeedbackType.other,
                    onTap: () => setState(() => _selectedType = FeedbackType.other),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Message input
              TextField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Describe tu feedback aquí...',
                  filled: true,
                  fillColor: NeoColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NeoColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NeoColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NeoColors.accent),
                  ),
                ),
              ),
              
              // Error message
              if (submitState == FeedbackSubmitState.error)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ref.read(feedbackNotifierProvider.notifier).lastError ?? 'Error desconocido',
                    style: const TextStyle(color: NeoColors.error),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitState == FeedbackSubmitState.submitting
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: submitState == FeedbackSubmitState.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enviar Feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _submit() {
    ref.read(feedbackNotifierProvider.notifier).submit(
      type: _selectedType,
      message: _messageController.text,
      currentRoute: widget.currentRoute,
    );
  }
}

/// Type selection chip
class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NeoColors.accent : NeoColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? NeoColors.accent : NeoColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : NeoColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
