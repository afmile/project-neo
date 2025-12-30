/// Project Neo - Profile Bio Card
///
/// Elegant card for displaying user bio with optional edit button
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class ProfileBioCard extends StatefulWidget {
  final String? bio;
  final bool isOwnProfile;
  final VoidCallback? onEditTap;

  const ProfileBioCard({
    super.key,
    this.bio,
    this.isOwnProfile = false,
    this.onEditTap,
  });

  @override
  State<ProfileBioCard> createState() => _ProfileBioCardState();
}

class _ProfileBioCardState extends State<ProfileBioCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.bio == null || widget.bio!.trim().isEmpty) {
      if (!widget.isOwnProfile) {
        return const SizedBox.shrink(); // Don't show empty bio for others
      }
      
      // Show placeholder for own profile
      return _buildCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Cuéntale a la comunidad sobre tí',
                style: NeoTextStyles.bodyMedium.copyWith(
                  color: NeoColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: NeoColors.accent,
              onPressed: widget.onEditTap,
            ),
          ],
        ),
      );
    }

    final bio = widget.bio!;
    final needsExpansion = bio.length > 150;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio text
          Text(
            _isExpanded || !needsExpansion ? bio : '${bio.substring(0, 150)}...',
            style: NeoTextStyles.bodyMedium.copyWith(
              color: NeoColors.textPrimary,
              height: 1.5,
            ),
          ),
          
          // Expand/collapse button
          if (needsExpansion) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Ver menos' : 'Ver más',
                style: NeoTextStyles.labelMedium.copyWith(
                  color: NeoColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          
          // Edit button for own profile
          if (widget.isOwnProfile) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onEditTap,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: NeoColors.accent,
                  textStyle: NeoTextStyles.labelMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeoColors.accent.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NeoColors.accent.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
