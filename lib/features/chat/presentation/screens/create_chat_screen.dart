import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/community_chat_room_provider.dart';

/// Screen for creating a new chat room
class CreateChatScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CreateChatScreen({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends ConsumerState<CreateChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Image bytes
  Uint8List? _iconBytes;
  String? _iconName;
  Uint8List? _backgroundBytes;
  String? _backgroundName;
  
  // Feature toggles
  bool _voiceEnabled = false;
  bool _videoEnabled = false;
  bool _projectionEnabled = false;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _iconBytes = bytes;
        _iconName = image.name;
      });
    }
  }

  Future<void> _pickBackground() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _backgroundBytes = bytes;
        _backgroundName = image.name;
      });
    }
  }

  Future<String?> _uploadImage(Uint8List bytes, String name, String folder) async {
    try {
      final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$name';
      
      await Supabase.instance.client.storage
          .from('chat-backgrounds')
          .uploadBinary(path, bytes);

      final publicUrl = Supabase.instance.client.storage
          .from('chat-backgrounds')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _createChat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload images if selected
      String? iconUrl;
      String? backgroundImageUrl;
      
      if (_iconBytes != null && _iconName != null) {
        iconUrl = await _uploadImage(_iconBytes!, _iconName!, 'icons');
      }
      
      if (_backgroundBytes != null && _backgroundName != null) {
        backgroundImageUrl = await _uploadImage(_backgroundBytes!, _backgroundName!, 'backgrounds');
      }

      // Create the channel
      final success = await ref
          .read(communityChatRoomProvider(widget.communityId).notifier)
          .createChannel(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            iconUrl: iconUrl,
            backgroundImageUrl: backgroundImageUrl,
            voiceEnabled: _voiceEnabled,
            videoEnabled: _videoEnabled,
            projectionEnabled: _projectionEnabled,
          );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Sala creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        // Get the actual error from the provider state
        final errorState = ref.read(communityChatRoomProvider(widget.communityId));
        final errorMsg = errorState.error ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excepción: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Crear Sala de Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createChat,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NeoColors.accent,
                    ),
                  )
                : const Text(
                    'Crear',
                    style: TextStyle(
                      color: NeoColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NeoSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════════
                // IMAGES SECTION
                // ═══════════════════════════════════════════════════════════
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Picker (1:1)
                    Expanded(
                      flex: 1,
                      child: _buildIconPicker(),
                    ),
                    const SizedBox(width: NeoSpacing.md),
                    // Background Picker (Portrait)
                    Expanded(
                      flex: 2,
                      child: _buildBackgroundPicker(),
                    ),
                  ],
                ),
                const SizedBox(height: NeoSpacing.xl),

                // ═══════════════════════════════════════════════════════════
                // TITLE FIELD
                // ═══════════════════════════════════════════════════════════
                Text(
                  'Título *',
                  style: NeoTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: NeoSpacing.sm),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ej: Sala General',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: NeoColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NeoColors.accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es obligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'El título debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: NeoSpacing.lg),

                // ═══════════════════════════════════════════════════════════
                // DESCRIPTION FIELD
                // ═══════════════════════════════════════════════════════════
                Text(
                  'Descripción',
                  style: NeoTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: NeoSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe de qué trata esta sala...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: NeoColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: NeoColors.accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: NeoSpacing.xl),

                // ═══════════════════════════════════════════════════════════
                // FEATURE TOGGLES
                // ═══════════════════════════════════════════════════════════
                Text(
                  'Funciones de la Sala',
                  style: NeoTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: NeoSpacing.sm),
                Text(
                  'Estas funciones usarán LiveKit cuando esté integrado',
                  style: NeoTextStyles.bodySmall.copyWith(
                    color: NeoColors.textTertiary,
                  ),
                ),
                const SizedBox(height: NeoSpacing.md),

                // Voice Toggle
                _buildFeatureToggle(
                  icon: Icons.mic_rounded,
                  title: 'Audio',
                  subtitle: 'Permitir chat de voz en esta sala',
                  value: _voiceEnabled,
                  onChanged: (val) => setState(() => _voiceEnabled = val),
                ),
                const SizedBox(height: NeoSpacing.sm),

                // Video Toggle
                _buildFeatureToggle(
                  icon: Icons.videocam_rounded,
                  title: 'Video',
                  subtitle: 'Permitir videollamadas en esta sala',
                  value: _videoEnabled,
                  onChanged: (val) => setState(() => _videoEnabled = val),
                ),
                const SizedBox(height: NeoSpacing.sm),

                // Projection Toggle
                _buildFeatureToggle(
                  icon: Icons.screen_share_rounded,
                  title: 'Proyección',
                  subtitle: 'Permitir compartir pantalla',
                  value: _projectionEnabled,
                  onChanged: (val) => setState(() => _projectionEnabled = val),
                ),

                const SizedBox(height: NeoSpacing.xl),

                // Info box
                Container(
                  padding: const EdgeInsets.all(NeoSpacing.md),
                  decoration: BoxDecoration(
                    color: NeoColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: NeoColors.accent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: NeoColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: NeoSpacing.sm),
                      Expanded(
                        child: Text(
                          'Una vez creada, podrás invitar a otros miembros a unirse.',
                          style: NeoTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // Extra padding for scroll
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icono',
          style: NeoTextStyles.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '1:1',
          style: NeoTextStyles.labelSmall.copyWith(
            color: NeoColors.textTertiary,
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        GestureDetector(
          onTap: _pickIcon,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: NeoColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: NeoColors.accent.withOpacity(0.5),
                  width: 2,
                ),
                image: _iconBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_iconBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _iconBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          size: 32,
                          color: NeoColors.accent.withOpacity(0.7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Icono',
                          style: NeoTextStyles.labelSmall.copyWith(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fondo',
          style: NeoTextStyles.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Vertical (9:16)',
          style: NeoTextStyles.labelSmall.copyWith(
            color: NeoColors.textTertiary,
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        GestureDetector(
          onTap: _pickBackground,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                color: NeoColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: NeoColors.accent.withOpacity(0.5),
                  width: 2,
                ),
                image: _backgroundBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_backgroundBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _backgroundBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wallpaper_rounded,
                          size: 40,
                          color: NeoColors.accent.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Imagen de\nFondo',
                          style: NeoTextStyles.labelSmall.copyWith(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Cambiar',
                              style: NeoTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? NeoColors.accent.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NeoSpacing.md,
          vertical: NeoSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: value
                ? NeoColors.accent.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: value ? NeoColors.accent : Colors.white54,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: NeoTextStyles.bodyMedium.copyWith(
            color: enabled ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: NeoTextStyles.labelSmall.copyWith(
            color: NeoColors.textTertiary,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: NeoColors.accent,
          inactiveTrackColor: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}
