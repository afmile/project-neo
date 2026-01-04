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
    // Hide bio card entirely if bio is empty (for both own and other profiles)
    if (widget.bio == null || widget.bio!.trim().isEmpty) {
      return const SizedBox.shrink();
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
