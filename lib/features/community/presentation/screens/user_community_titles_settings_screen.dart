/// Project Neo - User Community Titles Settings Screen
///
/// Allows users to manage their title display settings:
/// - Reorder titles via drag-and-drop
/// - Hide/show titles
/// - Toggle display mode (3 titles vs 2 rows)
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_titles_provider.dart';
import '../widgets/title_settings_item_widget.dart';
import '../widgets/hide_title_confirmation_dialog.dart';

class UserCommunityTitlesSettingsScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;
  final Color themeColor;

  const UserCommunityTitlesSettingsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.themeColor,
  });

  @override
  ConsumerState<UserCommunityTitlesSettingsScreen> createState() =>
      _UserCommunityTitlesSettingsScreenState();
}

class _UserCommunityTitlesSettingsScreenState
    extends ConsumerState<UserCommunityTitlesSettingsScreen> {
  Timer? _debounceTimer;
  bool _showMoreTitles = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), _saveOrder);
  }

  Future<void> _saveOrder() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final notifier = ref.read(
      userTitlesSettingsNotifierProvider(
        (userId: user.id, communityId: widget.communityId),
      ).notifier,
    );

    final success = await notifier.saveTitleOrders();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Orden guardado'),
            backgroundColor: widget.themeColor,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al guardar orden'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleHideTitle(String titleId, String titleName) async {
    // Show confirmation dialog
    final confirmed = await showHideTitleConfirmationDialog(
      context: context,
      titleName: titleName,
      themeColor: widget.themeColor,
    );

    if (!confirmed) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final notifier = ref.read(
      userTitlesSettingsNotifierProvider(
        (userId: user.id, communityId: widget.communityId),
      ).notifier,
    );

    final success = await notifier.hideTitle(titleId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Título ocultado'),
            backgroundColor: widget.themeColor,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al ocultar título'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleShowTitle(String titleId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final notifier = ref.read(
      userTitlesSettingsNotifierProvider(
        (userId: user.id, communityId: widget.communityId),
      ).notifier,
    );

    final success = await notifier.showTitle(titleId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Título visible'),
            backgroundColor: widget.themeColor,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al mostrar título'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
      userTitlesSettingsNotifierProvider(
        (userId: user.id, communityId: widget.communityId),
      ),
    );

    return Theme(
      data: NeoTheme.darkTheme(accentColor: widget.themeColor),
      child: Scaffold(
        backgroundColor: NeoColors.background,
        appBar: AppBar(
          backgroundColor: NeoColors.surface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mis Títulos',
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
        body: state.isLoading
            ? _buildShimmerLoading()
            : state.error != null
                ? _buildError(state.error!)
                : _buildContent(state, user.id),
      ),
    );
  }

  Widget _buildContent(TitleSettingsState state, String userId) {
    final titles = state.titles;

    if (titles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 64,
              color: NeoColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes títulos en esta comunidad',
              style: TextStyle(
                color: NeoColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header section
        _buildSectionHeader('Configuración'),
        const SizedBox(height: 8),
        
        // Display toggle
        Card(
          color: NeoColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            value: _showMoreTitles,
            onChanged: (value) {
              setState(() {
                _showMoreTitles = value;
              });
            },
            activeColor: widget.themeColor,
            activeTrackColor: widget.themeColor.withOpacity(0.4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showMoreTitles
                    ? widget.themeColor
                    : NeoColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.view_agenda_outlined,
                color: _showMoreTitles
                    ? Colors.white
                    : NeoColors.textSecondary,
                size: 20,
              ),
            ),
            title: const Text(
              'Mostrar más títulos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              _showMoreTitles
                  ? 'Hasta 2 filas en tu perfil'
                  : 'Solo 3 títulos en tu perfil',
              style: const TextStyle(
                color: NeoColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Titles list header
        _buildSectionHeader('Ordenar Títulos'),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Arrastra para cambiar el orden. Los primeros se mostrarán en tu perfil.',
            style: TextStyle(
              color: NeoColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Reorderable titles list
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: titles.length,
          onReorder: (oldIndex, newIndex) {
            final notifier = ref.read(
              userTitlesSettingsNotifierProvider(
                (userId: userId, communityId: widget.communityId),
              ).notifier,
            );
            
            notifier.reorderTitles(oldIndex, newIndex);
            _scheduleSave();
          },
          itemBuilder: (context, index) {
            final title = titles[index];
            
            return TitleSettingsItemWidget(
              key: ValueKey(title.id),
              title: title,
              themeColor: widget.themeColor,
              onHide: () => _handleHideTitle(title.id, title.title.name),
              onShow: () => _handleShowTitle(title.id),
            );
          },
        ),

        const SizedBox(height: 16),

        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NeoColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NeoColors.border),
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
                  'Los títulos ocultos no se eliminan. Puedes volver a mostrarlos en cualquier momento desde el menú ⋮',
                  style: TextStyle(
                    color: NeoColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: NeoColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                ref.invalidate(
                  userTitlesSettingsNotifierProvider(
                    (userId: user.id, communityId: widget.communityId),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: NeoColors.card,
      highlightColor: NeoColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 20, width: 100, color: Colors.white),
          const SizedBox(height: 16),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 20, width: 120, color: Colors.white),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
