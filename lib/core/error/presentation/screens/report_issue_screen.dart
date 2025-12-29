/// Project Neo - Report Issue Screen
///
/// Full-screen UI for submitting bug reports.
/// Accessible from error boundaries and global menu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/neo_theme.dart';
import '../../../theme/neo_widgets.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/bug_report_provider.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  final String? route;
  final String? communityId;
  final String? feature;
  final String? errorMessage;
  final String? error;
  final String? stackTrace;
  
  const ReportIssueScreen({
    super.key,
    this.route,
    this.communityId,
    this.feature,
    this.errorMessage,
    this.error,
    this.stackTrace,
  });

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _showContext = false;
  
  @override
  void initState() {
    super.initState();
    
    // Pre-fill description if error message is provided
    if (widget.errorMessage != null) {
      _descriptionController.text = 
          'Error encontrado: ${widget.errorMessage}\n\n';
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bugReportState = ref.watch(bugReportProvider);
    
    // Listen for success and pop
    ref.listen<BugReportState>(bugReportProvider, (previous, next) {
      if (next.isSuccess && previous?.isSuccess != true) {
        _showSuccessAndPop();
      }
    });
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reportar problema'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Text(
                'Describe el problema',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: NeoColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Tu reporte nos ayuda a mejorar la app. '
                'Incluye todos los detalles que puedas.',
                style: TextStyle(
                  fontSize: 14,
                  color: NeoColors.textSecondary,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Description field
              Container(
                decoration: BoxDecoration(
                  color: NeoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NeoColors.border,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 8,
                  style: TextStyle(
                    color: NeoColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ejemplo: "La app se cierra cuando intento...',
                    hintStyle: TextStyle(
                      color: NeoColors.textSecondary.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor describe el problema';
                    }
                    if (value.trim().length < 10) {
                      return 'La descripción debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Context section
              Container(
                decoration: BoxDecoration(
                  color: NeoColors.surfaceLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NeoColors.border.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showContext = !_showContext;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: NeoColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Información técnica incluida',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: NeoColors.textSecondary,
                                ),
                              ),
                            ),
                            Icon(
                              _showContext
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: NeoColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_showContext) ...[
                      Divider(
                        color: NeoColors.border.withOpacity(0.5),
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ContextItem(
                              label: 'Ruta',
                              value: widget.route ?? 'No disponible',
                            ),
                            if (widget.communityId != null)
                              _ContextItem(
                                label: 'Comunidad  ID',
                                value: widget.communityId!,
                              ),
                            if (widget.feature != null)
                              _ContextItem(
                                label: 'Función',
                                value: widget.feature!,
                              ),
                            _ContextItem(
                              label: 'Plataforma',
                              value: Theme.of(context).platform.toString(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: bugReportState.isSubmitting
                      ? null
                      : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoColors.accent,
                    foregroundColor: NeoColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: bugReportState.isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              NeoColors.background,
                            ),
                          ),
                        )
                      : const Text(
                          'Enviar reporte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              // Error message
              if (bugReportState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NeoColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NeoColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 20,
                        color: NeoColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bugReportState.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: NeoColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Build extra data from error context
    Map<String, dynamic>? extraData;
    if (widget.error != null || widget.stackTrace != null) {
      extraData = {
        if (widget.error != null) 'error': widget.error,
        if (widget.stackTrace != null) 'stack_trace': widget.stackTrace,
      };
    }
    
    await ref.read(bugReportProvider.notifier).submitReport(
      description: _descriptionController.text.trim(),
      route: widget.route ?? 'unknown',
      communityId: widget.communityId,
      feature: widget.feature,
      extraData: extraData,
    );
  }
  
  void _showSuccessAndPop() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Reporte enviado correctamente'),
        backgroundColor: NeoColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    // Reset provider and pop
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(bugReportProvider.notifier).reset();
      if (mounted) {
        context.pop();
      }
    });
  }
}

class _ContextItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _ContextItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: NeoColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: NeoColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
