/// Project Neo - Community Screen
///
/// Main community screen with parallax header, dynamic tabs, and Bento Feed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_tab_entity.dart';
import '../providers/community_provider.dart';
import '../widgets/community_header.dart';
import '../widgets/bento_feed.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  final String slug;
  
  const CommunityScreen({
    super.key,
    required this.slug,
  });

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _updateTabController(int length) {
    if (_tabController.length != length) {
      _tabController.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider(widget.slug));
    
    if (state.isLoading) {
      return _buildLoadingState();
    }
    
    if (state.error != null) {
      return _buildErrorState(state.error!);
    }
    
    final community = state.community;
    if (community == null) {
      return _buildNotFoundState();
    }
    
    // Get enabled tabs sorted by order
    final tabs = community.tabs
        .where((t) => t.isEnabled)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    // Update tab controller if needed
    if (tabs.isNotEmpty) {
      _updateTabController(tabs.length);
    }
    
    final accentColor = _parseColor(community.accentColor);
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Parallax header
          CommunityHeader(
            community: community,
            onJoin: () => ref.read(communityProvider(widget.slug).notifier).joinCommunity(),
          ),
          
          // Dynamic TabBar
          if (tabs.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabs: tabs,
                tabController: _tabController,
                accentColor: accentColor,
              ),
            ),
        ],
        body: tabs.isEmpty
            ? _buildFeedTab(state, accentColor)
            : TabBarView(
                controller: _tabController,
                children: tabs.map((tab) => _buildTabContent(tab, state, accentColor)).toList(),
              ),
      ),
      
      // FAB for new post
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewPostDialog(context),
        backgroundColor: accentColor,
        child: const Icon(Icons.add_rounded, color: NeoColors.textPrimary),
      ).animate().scale(delay: 500.ms),
    );
  }
  
  Widget _buildTabContent(CommunityTabEntity tab, CommunityState state, Color accentColor) {
    switch (tab.type) {
      case CommunityTabType.feed:
        return _buildFeedTab(state, accentColor);
      case CommunityTabType.chat:
        return _buildPlaceholderTab('Chat', Icons.chat_bubble_outline_rounded);
      case CommunityTabType.wiki:
        return _buildPlaceholderTab('Wiki', Icons.menu_book_rounded);
      case CommunityTabType.links:
        return _buildPlaceholderTab('Enlaces', Icons.link_rounded);
      case CommunityTabType.store:
        return _buildPlaceholderTab('Tienda', Icons.storefront_rounded);
      case CommunityTabType.events:
        return _buildPlaceholderTab('Eventos', Icons.event_rounded);
      case CommunityTabType.media:
        return _buildPlaceholderTab('Media', Icons.perm_media_rounded);
    }
  }
  
  Widget _buildFeedTab(CommunityState state, Color accentColor) {
    return CustomScrollView(
      slivers: [
        BentoFeed(
          posts: state.posts,
          accentColor: accentColor,
          onPostTap: (post) {
            // TODO: Navigate to post detail
          },
        ),
      ],
    );
  }
  
  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: NeoColors.textTertiary),
          const SizedBox(height: NeoSpacing.md),
          Text(
            title,
            style: NeoTextStyles.headlineSmall.copyWith(
              color: NeoColors.textSecondary,
            ),
          ),
          const SizedBox(height: NeoSpacing.xs),
          Text(
            'Próximamente',
            style: NeoTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: NeoSpacing.md),
            Text(
              'Cargando comunidad...',
              style: NeoTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: NeoColors.error),
            const SizedBox(height: NeoSpacing.md),
            Text('Error', style: NeoTextStyles.headlineSmall),
            const SizedBox(height: NeoSpacing.xs),
            Text(error, style: NeoTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: NeoSpacing.lg),
            ElevatedButton(
              onPressed: () => ref.refresh(communityProvider(widget.slug)),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotFoundState() {
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off_rounded, size: 64, color: NeoColors.textTertiary),
            const SizedBox(height: NeoSpacing.md),
            Text('Comunidad no encontrada', style: NeoTextStyles.headlineSmall),
          ],
        ),
      ),
    );
  }
  
  void _showNewPostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeoColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: NeoSpacing.lg,
          right: NeoSpacing.lg,
          top: NeoSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + NeoSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nueva publicación', style: NeoTextStyles.headlineMedium),
            const SizedBox(height: NeoSpacing.md),
            TextField(
              controller: titleController,
              style: NeoTextStyles.bodyLarge,
              decoration: const InputDecoration(hintText: 'Título'),
            ),
            const SizedBox(height: NeoSpacing.md),
            TextField(
              controller: contentController,
              style: NeoTextStyles.bodyLarge,
              decoration: const InputDecoration(hintText: 'Contenido'),
              maxLines: 4,
            ),
            const SizedBox(height: NeoSpacing.lg),
            ElevatedButton(
              onPressed: () {
                ref.read(communityProvider(widget.slug).notifier).createPost(
                  title: titleController.text,
                  content: contentController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Tab bar delegate for pinned header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<CommunityTabEntity> tabs;
  final TabController tabController;
  final Color accentColor;
  
  _TabBarDelegate({
    required this.tabs,
    required this.tabController,
    required this.accentColor,
  });
  
  @override
  double get minExtent => 48;
  
  @override
  double get maxExtent => 48;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: NeoColors.background,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: accentColor,
        indicatorWeight: 2,
        labelColor: NeoColors.textPrimary,
        unselectedLabelColor: NeoColors.textSecondary,
        labelStyle: NeoTextStyles.labelLarge,
        tabs: tabs.map((tab) => Tab(
          child: Row(
            children: [
              Icon(_getTabIcon(tab.type), size: 18),
              const SizedBox(width: 8),
              Text(tab.label),
            ],
          ),
        )).toList(),
      ),
    );
  }
  
  IconData _getTabIcon(CommunityTabType type) {
    switch (type) {
      case CommunityTabType.chat:
        return Icons.chat_bubble_outline_rounded;
      case CommunityTabType.feed:
        return Icons.dynamic_feed_rounded;
      case CommunityTabType.wiki:
        return Icons.menu_book_rounded;
      case CommunityTabType.links:
        return Icons.link_rounded;
      case CommunityTabType.store:
        return Icons.storefront_rounded;
      case CommunityTabType.events:
        return Icons.event_rounded;
      case CommunityTabType.media:
        return Icons.perm_media_rounded;
    }
  }
  
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return tabs != oldDelegate.tabs || tabController != oldDelegate.tabController;
  }
}
