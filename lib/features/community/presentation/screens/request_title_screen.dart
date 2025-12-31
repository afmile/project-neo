/// Project Neo - Request Title Screen
///
/// Screen for members to create custom title requests
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/title_request_providers.dart';
import '../widgets/color_picker_field.dart';
import '../widgets/title_preview_pill.dart';

class RequestTitleScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;
  final Color themeColor;

  const RequestTitleScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.themeColor,
  });

  @override
  ConsumerState<RequestTitleScreen> createState() => _RequestTitleScreenState();
}

class _RequestTitleScreenState extends ConsumerState<RequestTitleScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    final state = ref.watch(
      titleRequestCreationNotifierProvider(
        (communityId: widget.communityId, userId: user.id),
      ),
    );

    final notifier = ref.read(
      titleRequestCreationNotifierProvider(
        (communityId: widget.communityId, userId: user.id),
      ).notifier,
    );

    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        backgroundColor: NeoColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitar Título',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.communityName,
              style: const TextStyle(
                fontSize: 13,
                color: NeoColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.themeColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: widget.themeColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tu solicitud será revisada por los líderes de la comunidad. Una vez aprobada, el título aparecerá en tu perfil.',
                    style: TextStyle(
                      color: NeoColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Title text field
          const Text(
            'TEXTO DEL TÍTULO',
            style: TextStyle(
              color: NeoColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            style: const TextStyle(color: NeoColors.textPrimary),
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'Ej: Miembro VIP',
              hintStyle: const TextStyle(color: NeoColors.textTertiary),
              filled: true,
              fillColor: NeoColors.card,
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
                borderSide: BorderSide(color: widget.themeColor),
              ),
              counterStyle: const TextStyle(color: NeoColors.textTertiary),
            ),
            onChanged: (value) => notifier.updateTitleText(value),
          ),

          const SizedBox(height: 24),

          // Color pickers
          const Text(
            'COLORES',
            style: TextStyle(
              color: NeoColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          ColorPickerField(
            label: 'Color de Fondo',
            currentColor: state.backgroundColor,
            onColorChanged: notifier.updateBackgroundColor,
            icon: Icons.format_color_fill,
          ),

          const SizedBox(height: 12),

          ColorPickerField(
            label: 'Color de Texto',
            currentColor: state.textColor,
            onColorChanged: notifier.updateTextColor,
            icon: Icons.format_color_text,
          ),

          const SizedBox(height: 32),

          // Preview section
          const Text(
            'VISTA PREVIA',
            style: TextStyle(
              color: NeoColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NeoColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.border),
            ),
            child: Center(
              child: TitlePreviewPill(
                text: state.titleText,
                textColor: state.textColor,
                backgroundColor: state.backgroundColor,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: state.isLoading || !state.isValid
                ? null
                : () async {
                    final success = await notifier.submitRequest();
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✅ Solicitud enviada'),
                          backgroundColor: widget.themeColor,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: NeoColors.textTertiary,
            ),
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enviar Solicitud',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
