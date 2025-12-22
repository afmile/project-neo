import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/community_chat_room_provider.dart';
import '../widgets/pinned_room_card.dart';
import '../widgets/community_room_tile.dart';

class CommunityChatsScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityChatsScreen({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<CommunityChatsScreen> createState() =>
      _CommunityChatsScreenState();
}

class _CommunityChatsScreenState extends ConsumerState<CommunityChatsScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(communityChatRoomProvider(widget.communityId));
    final allPinnedRooms = ref.watch(pinnedRoomsProvider(widget.communityId));
    final allUnpinnedRooms = ref.watch(unpinnedRoomsProvider(widget.communityId));
    
    // Filter rooms based on search query
    final searchQuery = _searchController.text.toLowerCase();
    final pinnedRooms = searchQuery.isEmpty
        ? allPinnedRooms
        : allPinnedRooms
            .where((room) => room.title.toLowerCase().contains(searchQuery))
            .toList();
    final unpinnedRooms = searchQuery.isEmpty
        ? allUnpinnedRooms
        : allUnpinnedRooms
            .where((room) => room.title.toLowerCase().contains(searchQuery))
            .toList();
    
    // Check if user is NeoVip
    final user = ref.watch(currentUserProvider);
    final isNeoVip = user?.isNeoVip ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          // Close search when tapping outside
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
            _searchFocusNode.unfocus();
          }
        },
        child: SafeArea(
        child: roomState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: NeoColors.accent),
              )
            : Column(
                children: [
                  // Header
                  _buildHeader(context),
                  
                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.read(communityChatRoomProvider(widget.communityId).notifier).refreshRooms();
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: NeoColors.accent,
                      backgroundColor: NeoColors.card,
                      child: CustomScrollView(
                        slivers: [
                          // Pinned rooms section
                          if (pinnedRooms.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildPinnedSection(
                                context,
                                ref,
                                pinnedRooms,
                                isNeoVip,
                              ),
                            ),

                          // Unpinned rooms section
                          if (unpinnedRooms.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  NeoSpacing.md,
                                  NeoSpacing.lg,
                                  NeoSpacing.md,
                                  NeoSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.forum_rounded,
                                      size: 18,
                                      color: NeoColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Recientes',
                                      style: NeoTextStyles.headlineSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          SliverPadding(
                            padding: const EdgeInsets.all(NeoSpacing.md),
                            sliver: unpinnedRooms.isEmpty
                                ? SliverToBoxAdapter(
                                    child: _buildEmptyUnpinnedState(),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final room = unpinnedRooms[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: NeoSpacing.sm,
                                          ),
                                          child: CommunityRoomTile(
                                            room: room,
                                            communityId: widget.communityId,
                                            onTap: () {
                                              // TODO: Navigate to room conversation
                                            },
                                          ),
                                        );
                                      },
                                      childCount: unpinnedRooms.length,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeoSpacing.md,
        vertical: NeoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title - always visible
          Text(
            'Chats',
            style: NeoTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(width: NeoSpacing.md),
          
          // Animated Search Pill - expands in available space
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 48,
              alignment: Alignment.centerRight,
              child: _isSearching
                  ? _buildSearchField()
                  : _buildSearchButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          _isSearching = true;
        });
        // Auto-focus the search field
        Future.delayed(const Duration(milliseconds: 350), () {
          _searchFocusNode.requestFocus();
        });
      },
      icon: const Icon(
        Icons.search_rounded,
        color: Colors.white,
      ),
      style: IconButton.styleFrom(
        backgroundColor: NeoColors.card,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: NeoColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: NeoColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Buscar salas...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild to filter rooms
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
            _searchFocusNode.unfocus();
          },
          padding: const EdgeInsets.all(8),
          style: IconButton.styleFrom(
            backgroundColor: NeoColors.card,
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedSection(
    BuildContext context,
    WidgetRef ref,
    List pinnedRooms,
    bool isNeoVip,
  ) {
    final maxPins = isNeoVip ? 10 : 5;
    final displayRooms = pinnedRooms.take(maxPins).toList();

    return Container(
      padding: const EdgeInsets.all(NeoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.push_pin_rounded,
                size: 18,
                color: NeoColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Pinneadas',
                style: NeoTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isNeoVip)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'VIP',
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: NeoSpacing.md),

          // Pinned rooms grid/row
          if (isNeoVip && displayRooms.length > 5)
            // NeoVip with >5 pins: 2-row grid
            _buildPinnedGrid(context, ref, displayRooms)
          else
            // Normal or NeoVip with ≤5: Single row with scroll
            _buildPinnedRow(context, ref, displayRooms),
        ],
      ),
    );
  }

  Widget _buildPinnedRow(
    BuildContext context,
    WidgetRef ref,
    List displayRooms,
  ) {
    return SizedBox(
      height: 135, // Increased from 120 to prevent overflow when dragging
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayRooms.length,
        onReorder: (oldIndex, newIndex) {
          ref
              .read(communityChatRoomProvider(widget.communityId).notifier)
              .reorderPinned(oldIndex, newIndex);
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.1,
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final room = displayRooms[index];
          return Padding(
            key: ValueKey(room.id),
            padding: const EdgeInsets.only(right: NeoSpacing.sm),
            child: SizedBox(
              width: 140,
              child: PinnedRoomCard(
                room: room,
                communityId: widget.communityId,
                onTap: () {
                  // TODO: Navigate to room
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinnedGrid(
    BuildContext context,
    WidgetRef ref,
    List displayRooms,
  ) {
    return Wrap(
      spacing: NeoSpacing.sm,
      runSpacing: NeoSpacing.sm,
      children: List.generate(displayRooms.length, (index) {
        final room = displayRooms[index];
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 5 - 4,
          height: 120,
          child: GestureDetector(
            onLongPress: () {
              // Show reorder hint or unpin option
              _showPinOptions(context, ref, room);
            },
            child: PinnedRoomCard(
              room: room,
              communityId: widget.communityId,
              onTap: () {
                // TODO: Navigate to room
              },
            ),
          ),
        );
      }),
    );
  }

  void _showPinOptions(BuildContext context, WidgetRef ref, dynamic room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              room.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Unpin option
            ListTile(
              leading: const Icon(Icons.push_pin_outlined, color: Colors.white),
              title: const Text(
                'Despinnear',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(communityChatRoomProvider(widget.communityId).notifier)
                    .togglePin(room.id);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyUnpinnedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NeoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: NeoSpacing.md),
            Text(
              'No hay más salas',
              style: NeoTextStyles.bodyLarge.copyWith(
                color: NeoColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
