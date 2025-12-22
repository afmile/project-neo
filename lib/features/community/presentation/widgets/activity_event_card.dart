/// Project Neo - Activity Event Card
///
/// Timeline-style card for displaying friend activity
library;

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/activity_event.dart';

class ActivityEventCard extends StatelessWidget {
  final ActivityEvent event;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const ActivityEventCard({
    super.key,
    required this.event,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NeoSpacing.md,
          vertical: NeoSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline column (left side)
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Top line (hidden for first item)
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 12,
                      color: NeoColors.accent.withValues(alpha: 0.3),
                    ),
                  
                  // Dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NeoColors.accent,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                  
                  // Bottom line (hidden for last item)
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: NeoColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: NeoSpacing.md),
            
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(NeoSpacing.md),
                margin: const EdgeInsets.only(bottom: NeoSpacing.sm),
                decoration: BoxDecoration(
                  color: NeoColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Avatar + Name + Time
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: NeoColors.accent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: NeoColors.accent,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: NeoColors.accent,
                            size: 16,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Name and time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.username,
                                style: NeoTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeago.format(event.timestamp, locale: 'es'),
                                style: NeoTextStyles.bodySmall.copyWith(
                                  color: NeoColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Activity type emoji
                        Text(
                          event.type.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      event.type.description,
                      style: NeoTextStyles.bodySmall.copyWith(
                        color: NeoColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Title
                    Text(
                      event.title,
                      style: NeoTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    // Subtitle (if present)
                    if (event.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle!,
                        style: NeoTextStyles.bodySmall.copyWith(
                          color: NeoColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
