
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'Todo';
  final _filters = ['Todo', 'Mensajes', 'Comentarios', 'Likes', 'Sistema'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Notificaciones',
          style: NeoTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              // Settings dummy action
            },
            icon: const Icon(Icons.settings_outlined, color: NeoColors.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: NeoSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: NeoSpacing.sm),
            child: ChoiceChip(
              label: Text(
                filter,
                style: NeoTextStyles.labelMedium.copyWith(
                  color: isSelected ? Colors.white : NeoColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              backgroundColor: NeoColors.card,
              selectedColor: NeoColors.accent,
              side: BorderSide(
                color: isSelected ? NeoColors.accent : Colors.white10,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: NeoColors.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 40,
              color: NeoColors.textTertiary,
            ),
          ),
          const SizedBox(height: NeoSpacing.lg),
          Text(
            'Sin notificaciones',
            style: NeoTextStyles.headlineSmall,
          ),
          const SizedBox(height: NeoSpacing.sm),
          Text(
            'Estás al día con todo',
            style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
