/// Project Neo - Local Edit Profile Screen
///
/// Allows user to edit their local identity within a specific community.
/// Updates community_members table.
/// Fully reactive using ref.watch() for data loading.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/community_providers.dart';
import '../providers/local_identity_providers.dart';

class LocalEditProfileScreen extends ConsumerStatefulWidget {
  final String communityId;

  const LocalEditProfileScreen({
    super.key,
    required this.communityId,
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
  bool _initialized = false; // Track if controllers are initialized

  @override
  void initState() {
    super.initState();
    // Initialize controllers empty - will be populated when data arrives
    _nicknameController = TextEditingController();
    _bioController = TextEditingController();
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
      final fileName = 'local_${widget.communityId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
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
        ScaffoldMessenger.of(context).showSnackBar(
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
        // CRITICAL: Invalidate provider to refresh Home widget
        ref.invalidate(myLocalIdentityProvider(widget.communityId));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Identidad local actualizada'),
              backgroundColor: NeoColors.success,
              duration: Duration(milliseconds: 1500),
            ),
          );
          
          // Defer pop to avoid Navigator assertion
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
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
          SnackBar(content: Text('Error: $e'), backgroundColor: NeoColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // REACTIVE: Watch the provider
    final identityAsync = ref.watch(myLocalIdentityProvider(widget.communityId));
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mi Identidad Local'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: NeoColors.accent),
            onPressed: identityAsync.isLoading || _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: identityAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: NeoColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error cargando identidad',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (identity) {
          // Initialize controllers ONCE when data arrives
          if (!_initialized) {
            if (identity != null) {
              _nicknameController.text = identity.displayName;
              _bioController.text = identity.bio ?? '';
              _currentAvatarUrl = identity.avatarUrl;
            } else {
              // Fallback to global if no local identity exists yet
              final currentUser = ref.read(currentUserProvider);
              if (currentUser != null) {
                _nicknameController.text = currentUser.username;
                _bioController.text = '';
                _currentAvatarUrl = currentUser.avatarUrl;
              }
            }
            _initialized = true;
          }
          
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    return _isLoading 
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
          );
  }
}
