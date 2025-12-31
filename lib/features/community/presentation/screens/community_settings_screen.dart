import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/community_providers.dart';
import '../../data/repositories/community_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final notificationSettingsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, communityId) async {
  final repository = ref.read(communityRepositoryProvider);
  final user = ref.read(currentUserProvider);
  
  if (user == null) throw Exception("User not authenticated");

  return repository.getNotificationSettings(
    communityId: communityId,
    userId: user.id,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class CommunitySettingsScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;
  final Color themeColor;

  const CommunitySettingsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.themeColor,
  });

  @override
  ConsumerState<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends ConsumerState<CommunitySettingsScreen> {
  // Local state for optimistic updates
  Map<String, dynamic>? _localSettings;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSettingChanged(String key, bool value) {
    if (_localSettings == null) return;

    setState(() {
      _localSettings![key] = value;
      // Optimistic logic: if globally disabled, visually keep others as they were but they effectively don't work
    });

    _scheduleSave();
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _saveSettings);
  }

  Future<void> _saveSettings() async {
    if (_localSettings == null) {
      print('⚠️ _saveSettings: _localSettings is null, returning');
      return;
    }

    print('🔧 _saveSettings: Iniciando guardado');
    print('   Community ID: ${widget.communityId}');
    print('   Settings: $_localSettings');

    try {
      final repository = ref.read(communityRepositoryProvider);
      final user = ref.read(currentUserProvider);
      
      print('👤 User ID: ${user?.id}');
      
      if (user == null) {
        print('❌ Usuario no autenticado');
        return;
      }

      print('💾 Llamando a repository.updateNotificationSettings...');
      await repository.updateNotificationSettings(
        communityId: widget.communityId,
        userId: user.id,
        settings: _localSettings!,
      );

      print('✅ Guardado exitoso');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Configuración actualizada'),
            backgroundColor: widget.themeColor,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      print('❌ Error al guardar: $e');
      print('📚 Stack trace: $stack');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Revertir estado local recargando provider
        ref.refresh(notificationSettingsProvider(widget.communityId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider(widget.communityId));

    // Initialize local settings once when data loads
    if (_localSettings == null && settingsAsync.hasValue) {
      // Create a mutable copy
      _localSettings = Map<String, dynamic>.from(settingsAsync.value!);
    }

    return Theme(
      data: NeoTheme.darkTheme(accentColor: widget.themeColor),
      child: Scaffold(
        backgroundColor: NeoColors.background,
        appBar: AppBar(
          backgroundColor: NeoColors.surface,
          title: Text(
            widget.communityName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: settingsAsync.when(
          data: (_) => _buildContent(),
          loading: () => _buildShimmerLoading(),
          error: (err, stack) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_localSettings == null) return const SizedBox.shrink();

    final enabled = _localSettings!['enabled'] == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Preferencias'),
        const SizedBox(height: 8),
        
        // Main Card
        Card(
          color: NeoColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Master Switch
                _buildSwitchTile(
                  title: 'Activar notificaciones',
                  subtitle: 'Gestiona todas las alertas de esta comunidad',
                  icon: Icons.notifications,
                  value: enabled,
                  isMaster: true,
                  onChanged: (v) => _onSettingChanged('enabled', v),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: NeoColors.border),
                ),

                // Granular Controls
                Opacity(
                  opacity: enabled ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !enabled,
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Mensajes de chat',
                          icon: Icons.chat_bubble_outline,
                          value: _localSettings!['chat'] == true,
                          onChanged: (v) => _onSettingChanged('chat', v),
                        ),
                        _buildSwitchTile(
                          title: 'Menciones',
                          icon: Icons.alternate_email,
                          value: _localSettings!['mentions'] == true,
                          onChanged: (v) => _onSettingChanged('mentions', v),
                        ),
                        _buildSwitchTile(
                          title: 'Anuncios',
                          icon: Icons.campaign_outlined,
                          value: _localSettings!['announcements'] == true,
                          onChanged: (v) => _onSettingChanged('announcements', v),
                        ),
                        _buildSwitchTile(
                          title: 'Nuevos posts',
                          icon: Icons.article_outlined,
                          value: _localSettings!['wall_posts'] == true,
                          onChanged: (v) => _onSettingChanged('wall_posts', v),
                        ),
                        _buildSwitchTile(
                          title: 'Reacciones',
                          icon: Icons.favorite_border,
                          value: _localSettings!['reactions'] == true,
                          onChanged: (v) => _onSettingChanged('reactions', v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isMaster = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: value && isMaster
          ? BoxDecoration(
              color: widget.themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.themeColor.withOpacity(0.3)),
            )
          : null,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: widget.themeColor,
        activeTrackColor: widget.themeColor.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMaster ? widget.themeColor : NeoColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isMaster ? Colors.white : NeoColors.textSecondary,
            size: isMaster ? 22 : 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isMaster ? FontWeight.bold : FontWeight.w500,
            fontSize: isMaster ? 16 : 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: NeoColors.textSecondary, fontSize: 13),
              )
            : null,
      ),
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: NeoColors.card,
      highlightColor: NeoColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 20, width: 100, color: Colors.white),
          const SizedBox(height: 16),
          Container(height: 400, decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          )),
        ],
      ),
    );
  }
}
