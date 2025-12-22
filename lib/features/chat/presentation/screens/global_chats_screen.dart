import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/global_chat_provider.dart';
import '../widgets/global_chat_tile.dart';

class GlobalChatsScreen extends ConsumerWidget {
  const GlobalChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(globalChatProvider);
    final chats = chatState.chats;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Chat List
            Expanded(
              child: chatState.isLoading
                  ? _buildLoadingState()
                  : chats.isEmpty
                      ? _buildEmptyState(context)
                      : _buildChatList(context, ref, chats),
            ),
          ],
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
          Text(
            'Chats',
            style: NeoTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Búsqueda - Próximamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: NeoColors.card,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: NeoColors.accent,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NeoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoColors.accent.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 40,
                color: NeoColors.accent,
              ),
            ),
            const SizedBox(height: NeoSpacing.lg),
            Text(
              'No hay chats favoritos',
              style: NeoTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeoSpacing.sm),
            Text(
              'Marca chats como favoritos desde las comunidades para verlos aquí',
              style: NeoTextStyles.bodyMedium.copyWith(
                color: NeoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, WidgetRef ref, List chats) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(globalChatProvider.notifier).refreshChats();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: NeoColors.accent,
      backgroundColor: NeoColors.card,
      child: ListView.separated(
        padding: const EdgeInsets.all(NeoSpacing.md),
        itemCount: chats.length,
        separatorBuilder: (context, index) => const SizedBox(height: NeoSpacing.sm),
        itemBuilder: (context, index) {
          final chat = chats[index];
          
          // Wrap with Slidable for swipe-to-unfavorite
          return Slidable(
            key: ValueKey(chat.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (context) {
                    ref.read(globalChatProvider.notifier).unfavoriteChat(chat.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${chat.title} eliminado de favoritos'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Deshacer',
                          onPressed: () {
                            // TODO: Implement undo
                          },
                        ),
                      ),
                    );
                  },
                  backgroundColor: NeoColors.error,
                  foregroundColor: Colors.white,
                  icon: Icons.star_border_rounded,
                  label: 'Quitar',
                ),
              ],
            ),
            child: GlobalChatTile(
              chat: chat,
              onTap: () {
                // Navigate to conversation
                context.push('/chat/${chat.id}', extra: chat);
              },
            ),
          );
        },
      ),
    );
  }
}
