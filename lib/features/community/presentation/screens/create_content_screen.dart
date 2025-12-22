/// Project Neo - Create Content Screen
///
/// Unified content creation screen for Blog, Wiki, Poll types with auto-save.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/draft_service.dart';
import '../../domain/entities/post_entity.dart';
import '../../data/models/post_model.dart';
import '../providers/content_providers.dart';

class CreateContentScreen extends ConsumerStatefulWidget {
  final String communityId;
  final PostType postType;
  final String? communityName;

  const CreateContentScreen({
    super.key,
    required this.communityId,
    required this.postType,
    this.communityName,
  });

  @override
  ConsumerState<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends ConsumerState<CreateContentScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _pollOptionControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  
  Timer? _autoSaveTimer;
  bool _isPublishing = false;
  bool _hasCheckedDraft = false;
  String? _coverImageUrl;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _setupAutoSave();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setupAutoSave() {
    // Auto-save every 2 seconds after text changes
    _titleController.addListener(_scheduleSave);
    _contentController.addListener(_scheduleSave);
  }

  void _scheduleSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (_currentUserId == null) return;
    
    final draftService = ref.read(draftServiceProvider);
    await draftService.saveDraft(
      userId: _currentUserId!,
      communityId: widget.communityId,
      type: widget.postType,
      title: _titleController.text,
      content: _contentController.text,
      coverImageUrl: _coverImageUrl,
      pollOptions: widget.postType == PostType.poll 
          ? _pollOptionControllers.map((c) => c.text).toList()
          : null,
    );
  }

  Future<void> _checkForDraft() async {
    if (_hasCheckedDraft || _currentUserId == null) return;
    _hasCheckedDraft = true;

    final draftService = ref.read(draftServiceProvider);
    final draft = await draftService.getDraft(
      userId: _currentUserId!,
      communityId: widget.communityId,
      type: widget.postType,
    );

    if (draft != null && draft.hasContent && mounted) {
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '📝 Borrador encontrado',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Guardado ${_formatTimeAgo(draft.savedAt)}. ¿Deseas restaurarlo?',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Descartar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );

      if (shouldRestore == true && mounted) {
        _titleController.text = draft.title;
        _contentController.text = draft.content;
        _coverImageUrl = draft.coverImageUrl;
        
        if (draft.pollOptions != null) {
          for (var i = 0; i < draft.pollOptions!.length; i++) {
            if (i < _pollOptionControllers.length) {
              _pollOptionControllers[i].text = draft.pollOptions![i];
            } else {
              _pollOptionControllers.add(TextEditingController(text: draft.pollOptions![i]));
            }
          }
          setState(() {});
        }
      } else if (shouldRestore == false) {
        // Clear the draft if user doesn't want it
        await draftService.clearDraft(
          userId: _currentUserId!,
          communityId: widget.communityId,
          type: widget.postType,
        );
      }
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} horas';
    return 'hace ${diff.inDays} días';
  }

  Future<void> _publish() async {
    if (_currentUserId == null) {
      _showError('Debes iniciar sesión');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showError('El título es requerido');
      return;
    }

    if (widget.postType == PostType.poll) {
      final validOptions = _pollOptionControllers
          .where((c) => c.text.trim().isNotEmpty)
          .toList();
      if (validOptions.length < 2) {
        _showError('Necesitas al menos 2 opciones');
        return;
      }
    }

    setState(() => _isPublishing = true);

    try {
      final repository = ref.read(contentRepositoryProvider);
      
      // Create the post
      final post = PostModel(
        id: '',  // Will be generated by DB
        communityId: widget.communityId,
        authorId: _currentUserId!,
        postType: widget.postType,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        coverImageUrl: _coverImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await repository.createPost(post);

      await result.fold(
        (failure) async {
          _showError(failure.message);
        },
        (createdPost) async {
          // If poll, create options
          if (widget.postType == PostType.poll) {
            final options = _pollOptionControllers
                .map((c) => c.text.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            
            await repository.createPollOptions(
              postId: createdPost.id,
              options: options,
            );
          }

          // Clear draft
          final draftService = ref.read(draftServiceProvider);
          await draftService.clearDraft(
            userId: _currentUserId!,
            communityId: widget.communityId,
            type: widget.postType,
          );

          // Refresh feed
          ref.invalidate(feedProvider((
            communityId: widget.communityId,
            typeFilter: null,
          )));

          if (mounted) {
            Navigator.pop(context, createdPost);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.postType.displayName} publicado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Crear ${widget.postType.displayName}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _isPublishing
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : ElevatedButton(
                  onPressed: _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Publicar'),
                ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image for blog/wiki
          if (widget.postType == PostType.blog || widget.postType == PostType.wiki)
            _buildCoverImageSection(),
          
          const SizedBox(height: 16),
          
          // Title field
          _buildTitleField(),
          
          const SizedBox(height: 16),
          
          // Content based on type
          if (widget.postType == PostType.poll)
            _buildPollOptions()
          else
            _buildContentField(),
          
          const SizedBox(height: 32),
          
          // Auto-save indicator
          Center(
            child: Text(
              '✓ Auto-guardado activado',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement image picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selector de imagen próximamente')),
        );
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _coverImageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(_coverImageUrl!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _coverImageUrl = null),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Añadir portada',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: widget.postType == PostType.poll 
            ? '¿Cuál es tu pregunta?'
            : 'Título',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
    );
  }

  Widget _buildContentField() {
    return TextField(
      controller: _contentController,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 16,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: widget.postType == PostType.wiki
            ? 'Escribe el contenido de tu wiki...'
            : 'Comparte tu historia...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      minLines: 10,
    );
  }

  Widget _buildPollOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        ...List.generate(_pollOptionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pollOptionControllers[index],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Opción ${index + 1}',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                if (_pollOptionControllers.length > 2)
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _pollOptionControllers[index].dispose();
                        _pollOptionControllers.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
          );
        }),
        
        if (_pollOptionControllers.length < 6)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _pollOptionControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Añadir opción'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
          ),
      ],
    );
  }
}
