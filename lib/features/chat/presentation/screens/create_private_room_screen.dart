import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';

class CreatePrivateRoomScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CreatePrivateRoomScreen({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<CreatePrivateRoomScreen> createState() =>
      _CreatePrivateRoomScreenState();
}

class _CreatePrivateRoomScreenState
    extends ConsumerState<CreatePrivateRoomScreen> {
  final _groupNameController = TextEditingController();
  final Set<String> _selectedFriendIds = {};

  // Mock friends data (mutual followers only)
  final List<UserEntity> _mockFriends = [
    UserEntity(
      id: 'friend_1',
      username: 'anagarcia',
      email: 'ana@example.com',
      displayName: 'Ana García',
      avatarUrl: null,
      isVip: true,
      createdAt: DateTime.now(),
    ),
    UserEntity(
      id: 'friend_2',
      username: 'carlosruiz',
      email: 'carlos@example.com',
      displayName: 'Carlos Ruiz',
      avatarUrl: null,
      isVip: false,
      createdAt: DateTime.now(),
    ),
    UserEntity(
      id: 'friend_3',
      username: 'marialopez',
      email: 'maria@example.com',
      displayName: 'María López',
      avatarUrl: null,
      isVip: true,
      createdAt: DateTime.now(),
    ),
    UserEntity(
      id: 'friend_4',
      username: 'pedrosanchez',
      email: 'pedro@example.com',
      displayName: 'Pedro Sánchez',
      avatarUrl: null,
      isVip: false,
      createdAt: DateTime.now(),
    ),
    UserEntity(
      id: 'friend_5',
      username: 'lauramartinez',
      email: 'laura@example.com',
      displayName: 'Laura Martínez',
      avatarUrl: null,
      isVip: false,
      createdAt: DateTime.now(),
    ),
    UserEntity(
      id: 'friend_6',
      username: 'diegotorres',
      email: 'diego@example.com',
      displayName: 'Diego Torres',
      avatarUrl: null,
      isVip: true,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  bool get _canCreateRoom => _selectedFriendIds.length >= 2;

  String _generateAutoName() {
    if (_selectedFriendIds.isEmpty) return '';
    
    final selectedFriends = _mockFriends
        .where((friend) => _selectedFriendIds.contains(friend.id))
        .toList();
    
    if (selectedFriends.length <= 3) {
      return selectedFriends.map((f) => f.displayName?.split(' ').first ?? f.username).join(', ');
    } else {
      final firstTwo = selectedFriends.take(2).map((f) => f.displayName?.split(' ').first ?? f.username).join(', ');
      return '$firstTwo y ${selectedFriends.length - 2} más';
    }
  }

  void _createRoom() {
    if (!_canCreateRoom) return;

    final roomName = _groupNameController.text.trim().isEmpty
        ? _generateAutoName()
        : _groupNameController.text.trim();

    // TODO: Create the actual room entity and save it
    // For now, just show success and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sala "$roomName" creada con ${_selectedFriendIds.length} amigos'),
        backgroundColor: NeoColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
    // TODO: Navigate to ChatConversationScreen with the new room
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Nueva Sala Privada'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Group name input
          Container(
            padding: const EdgeInsets.all(NeoSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre del Grupo (Opcional)',
                  style: NeoTextStyles.labelMedium.copyWith(
                    color: NeoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _groupNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _selectedFriendIds.isEmpty
                        ? 'Ej: Amigos del Gaming'
                        : _generateAutoName(),
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: NeoColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),

          // Selection counter
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NeoSpacing.md,
              vertical: NeoSpacing.sm,
            ),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 20,
                  color: _canCreateRoom ? NeoColors.accent : NeoColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedFriendIds.length} amigos seleccionados',
                  style: NeoTextStyles.bodyMedium.copyWith(
                    color: _canCreateRoom ? NeoColors.accent : NeoColors.textTertiary,
                    fontWeight: _canCreateRoom ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (!_canCreateRoom) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(mínimo 2)',
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: NeoColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Friends list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(NeoSpacing.md),
              itemCount: _mockFriends.length,
              itemBuilder: (context, index) {
                final friend = _mockFriends[index];
                final isSelected = _selectedFriendIds.contains(friend.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: NeoSpacing.sm),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFriendIds.remove(friend.id);
                        } else {
                          _selectedFriendIds.add(friend.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(NeoSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? NeoColors.accent.withValues(alpha: 0.1)
                            : NeoColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? NeoColors.accent
                              : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: NeoColors.accent.withValues(alpha: 0.2),
                              border: Border.all(
                                color: friend.isNeoVip
                                    ? const Color(0xFFEC4899)
                                    : NeoColors.accent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              color: friend.isNeoVip
                                  ? const Color(0xFFEC4899)
                                  : NeoColors.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: NeoSpacing.md),

                          // Name and VIP badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        friend.displayName ?? friend.username,
                                        style: NeoTextStyles.bodyLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (friend.isNeoVip) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'VIP',
                                          style: NeoTextStyles.labelSmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${friend.username}',
                                  style: NeoTextStyles.bodySmall.copyWith(
                                    color: NeoColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Checkbox
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedFriendIds.add(friend.id);
                                } else {
                                  _selectedFriendIds.remove(friend.id);
                                }
                              });
                            },
                            activeColor: NeoColors.accent,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(NeoSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _canCreateRoom ? _createRoom : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.accent,
              disabledBackgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _canCreateRoom ? 8 : 0,
            ),
            child: Text(
              _canCreateRoom
                  ? 'Crear Sala (${_selectedFriendIds.length} amigos)'
                  : 'Selecciona al menos 2 amigos',
              style: NeoTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
