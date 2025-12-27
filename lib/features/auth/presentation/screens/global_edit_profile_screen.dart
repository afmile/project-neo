/// Project Neo - Global Edit Profile Screen
///
/// Allows user to edit their global identity (Passport).
/// Updates users_global table.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../presentation/providers/auth_provider.dart';

class GlobalEditProfileScreen extends ConsumerStatefulWidget {
  const GlobalEditProfileScreen({super.key});

  @override
  ConsumerState<GlobalEditProfileScreen> createState() => _GlobalEditProfileScreenState();
}

class _GlobalEditProfileScreenState extends ConsumerState<GlobalEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  File? _imageFile;
  String? _currentAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _loadUserData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _usernameController.text = user.username;
      _bioController.text = user.bio ?? '';
      _currentAvatarUrl = user.avatarUrl;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
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
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName; // Root of bucket or folder? Let's use root for simplicity or userId/

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(
            filePath,
            _imageFile!,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);
          
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imagen: $e'), backgroundColor: NeoColors.error),
      );
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

      final success = await ref.read(authProvider.notifier).updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: NeoColors.success),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          final error = ref.read(authProvider).error ?? 'Error desconocido';
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
        title: const Text('Editar Perfil Global'),
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
                    
                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre de Usuario Global',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.alternate_email, color: NeoColors.accent),
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
                        if (value == null || value.isEmpty) return 'El usuario no puede estar vacío';
                        if (value.length < 3) return 'Mínimo 3 caracteres';
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
                        labelText: 'Biografía (Global)',
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
                    Text(
                      'Este es tu perfil PASAPORTE. Se usará como base cuando te unas a nuevas comunidades.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
