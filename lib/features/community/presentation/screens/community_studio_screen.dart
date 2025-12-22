/// Project Neo - Community Studio (Neo Studio)
///
/// Community management panel for owners/admins.
/// Inspired by Amino's ACM redesigned for Project Neo.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/community_providers.dart';

class CommunityStudioScreen extends ConsumerStatefulWidget {
  final CommunityEntity community;

  const CommunityStudioScreen({super.key, required this.community});

  @override
  ConsumerState<CommunityStudioScreen> createState() => _CommunityStudioScreenState();
}

class _CommunityStudioScreenState extends ConsumerState<CommunityStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, bool> _moduleConfig;
  bool _isSaving = false;

  Color get _accentColor {
    try {
      final hex = widget.community.theme.primaryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return NeoColors.accent;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize module config from community or defaults
    _moduleConfig = {
      'chat': true,
      'posts': true,
      'wiki': true,
      'polls': true,
      'quizzes': false,
      'voice': false,
      'rankings': true,
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NeoTheme.darkTheme(accentColor: _accentColor),
      child: Scaffold(
        backgroundColor: NeoColors.background,
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPanelTab(),
            _buildCustomizeTab(),
            _buildMembersTab(),
            _buildStatsTab(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: NeoColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(8),
              image: widget.community.iconUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.community.iconUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.community.iconUrl == null
                ? Center(
                    child: Text(
                      widget.community.title[0].toUpperCase(),
                      style: NeoTextStyles.labelLarge.copyWith(color: Colors.white),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Neo Studio',
                  style: NeoTextStyles.labelMedium.copyWith(
                    color: _accentColor,
                  ),
                ),
                Text(
                  widget.community.title,
                  style: NeoTextStyles.labelLarge.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: _accentColor,
        labelColor: _accentColor,
        unselectedLabelColor: NeoColors.textSecondary,
        labelStyle: NeoTextStyles.labelMedium,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Panel'),
          Tab(icon: Icon(Icons.palette), text: 'Personalizar'),
          Tab(icon: Icon(Icons.people), text: 'Miembros'),
          Tab(icon: Icon(Icons.analytics), text: 'Stats'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PANEL TAB - Overview
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPanelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  value: widget.community.memberCount.toString(),
                  label: 'Miembros',
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.article,
                  value: '0',
                  label: 'Posts',
                  color: NeoColors.success,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.visibility,
                  value: '0',
                  label: 'Visitas hoy',
                  color: NeoColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  value: '+0%',
                  label: 'Crecimiento',
                  color: NeoColors.warning,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // Quick Actions
          Text(
            'Acciones Rápidas',
            style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionButton(
                icon: Icons.edit,
                label: 'Editar Info',
                color: _accentColor,
                onTap: () {},
              ),
              _QuickActionButton(
                icon: Icons.shield,
                label: 'Moderación',
                color: NeoColors.warning,
                onTap: () {},
              ),
              _QuickActionButton(
                icon: Icons.campaign,
                label: 'Anuncio',
                color: NeoColors.success,
                onTap: () {},
              ),
              _QuickActionButton(
                icon: Icons.link,
                label: 'Invitar',
                color: NeoColors.info,
                onTap: () => _showInviteDialog(),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMIZE TAB - Module Toggles
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCustomizeTab() {
    final modules = [
      _ModuleInfo('chat', Icons.chat_bubble, 'Chat', 'Mensajería en tiempo real', const Color(0xFF3B82F6)),
      _ModuleInfo('posts', Icons.article, 'Publicaciones', 'Blog y posts de la comunidad', const Color(0xFF10B981)),
      _ModuleInfo('wiki', Icons.menu_book, 'Wiki', 'Enciclopedia colaborativa', const Color(0xFF8B5CF6)),
      _ModuleInfo('polls', Icons.poll, 'Encuestas', 'Votaciones y opiniones', const Color(0xFFF59E0B)),
      _ModuleInfo('quizzes', Icons.quiz, 'Quizzes', 'Trivias y cuestionarios', const Color(0xFFEC4899)),
      _ModuleInfo('voice', Icons.mic, 'Voz', 'Salas de voz en vivo', const Color(0xFF06B6D4)),
      _ModuleInfo('rankings', Icons.leaderboard, 'Rankings', 'Tablas de clasificación', const Color(0xFFEF4444)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.extension, color: _accentColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Módulos',
                        style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
                      ),
                      Text(
                        'Activa o desactiva funcionalidades',
                        style: NeoTextStyles.bodySmall.copyWith(color: NeoColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          // Module Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              final isEnabled = _moduleConfig[module.key] ?? false;

              return _ModuleCard(
                module: module,
                isEnabled: isEnabled,
                onToggle: () => _toggleModule(module.key),
              ).animate(delay: (index * 80).ms).fadeIn().scale(
                begin: const Offset(0.9, 0.9),
                duration: 300.ms,
              );
            },
          ),

          const SizedBox(height: 24),

          // Save Button
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveModuleConfig,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleModule(String key) {
    setState(() {
      _moduleConfig[key] = !(_moduleConfig[key] ?? false);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _saveModuleConfig() async {
    setState(() => _isSaving = true);

    // TODO: Implement actual save to Supabase
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuración guardada'),
          backgroundColor: NeoColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEMBERS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMembersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: NeoColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Gestión de Miembros',
            style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente',
            style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: NeoColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Estadísticas',
            style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente',
            style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showInviteDialog() {
    final inviteCode = 'neo.app/${widget.community.slug}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeoColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.link, color: _accentColor),
            const SizedBox(width: 12),
            Text('Invitar', style: NeoTextStyles.headlineMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NeoColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteCode,
                      style: NeoTextStyles.bodyLarge.copyWith(color: _accentColor),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: _accentColor),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Enlace copiado'),
                          backgroundColor: NeoColors.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: NeoTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: NeoTextStyles.bodySmall.copyWith(color: NeoColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: NeoTextStyles.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleInfo {
  final String key;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ModuleInfo(this.key, this.icon, this.title, this.description, this.color);
}

class _ModuleCard extends StatelessWidget {
  final _ModuleInfo module;
  final bool isEnabled;
  final VoidCallback onToggle;

  const _ModuleCard({
    required this.module,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? module.color.withOpacity(0.15) : NeoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? module.color : NeoColors.border,
            width: isEnabled ? 2 : 1,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: module.color.withOpacity(0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnabled ? module.color : NeoColors.elevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(module.icon, color: Colors.white, size: 20),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (_) => onToggle(),
                  activeColor: module.color,
                  activeTrackColor: module.color.withOpacity(0.3),
                ),
              ],
            ),
            const Spacer(),
            Text(
              module.title,
              style: NeoTextStyles.labelLarge.copyWith(
                color: isEnabled ? module.color : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              module.description,
              style: NeoTextStyles.bodySmall.copyWith(
                color: NeoColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
