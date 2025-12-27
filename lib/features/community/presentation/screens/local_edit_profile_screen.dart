/// Project Neo - Local Edit Profile Screen
///
/// Allows user to edit their local identity within a specific community.
/// Updates community_members table.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/community_providers.dart';

class LocalEditProfileScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String initialNickname;
  final String? initialAvatarUrl;
  final String? initialBio;

  const LocalEditProfileScreen({
    super.key,
    required this.communityId,
    required this.initialNickname,
    this.initialAvatarUrl,
    this.initialBio,
  });

  @override
  ConsumerState<LocalEditProfileScreen> createState() => _LocalEditProfileScreenState();
}

class _LocalEditProfileScreenState extends ConsumerState<LocalEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  
  File? _imageFile;
  String? _currentAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialNickname);
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    _currentAvatarUrl = widget.initialAvatarUrl;
  }
  
  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_imageFile == null) return null;

    try {
      final fileExt = _imageFile!.path.split('.').last;
      // Use consistent naming pattern but scoped to community/user to avoid collisions if we wanted distinct files
      // But effectively we can just rename it. 
      // Let's use `local_{communityId}_{userId}_{timestamp}.jpg`
      final fileName = 'local_${widget.communityId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // We can reuse the avatars bucket. The 015 migration allows authenticated users to upload.
      // Ideally we organize in folders but flat is fine for MVP + RLS.
      // Let's try to put it in a 'local' folder if possible, or just root.
      // Existing RLS is fairly open for auth users.
      
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(
            fileName,
            _imageFile!,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
          
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Error subiendo imagen: $e'), backgroundColor: NeoColors.error),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Usuario no autenticado');

      String? newAvatarUrl = _currentAvatarUrl;
      
      // Upload image if changed
      if (_imageFile != null) {
        final uploadedUrl = await _uploadAvatar(user.id);
        if (uploadedUrl != null) {
          newAvatarUrl = uploadedUrl;
        }
      }

      final success = await ref.read(communityActionsProvider.notifier).updateLocalProfile(
        communityId: widget.communityId,
        nickname: _nicknameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil local actualizado correctamente'), backgroundColor: NeoColors.success),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          final error = ref.read(communityActionsProvider).error ?? 'Error desconocido';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error'), backgroundColor: NeoColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e'), backgroundColor: NeoColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Editar Perfil Local'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: NeoColors.accent),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: NeoColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(NeoSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: NeoColors.accent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: NeoColors.accent.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : _currentAvatarUrl != null
                                      ? Image.network(_currentAvatarUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 60, color: Colors.grey),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: NeoColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Nickname Field
                    TextFormField(
                      controller: _nicknameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Apodo en la Comunidad',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.badge_outlined, color: NeoColors.accent),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: NeoColors.accent),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El apodo no puede estar vacío';
                        if (value.length < 2) return 'Mínimo 2 caracteres';
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Biografía Local',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.edit_note, color: NeoColors.accent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: NeoColors.accent),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NeoColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: NeoColors.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Estos cambios SOLO afectan tu identidad en esta comunidad. Tu pasaporte Global permanece intacto.',
                              style: TextStyle(color: NeoColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
