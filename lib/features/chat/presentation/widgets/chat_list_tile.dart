import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../domain/entities/message_entity.dart';

/// Tuile de conversation dans la liste des chats.
class ChatListTile extends StatelessWidget {
  final ChatEntity chat;
  final String currentUserId;
  final VoidCallback? onTap;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.onTap,
  });

  String get _otherUserId =>
      chat.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => chat.participantIds.first,
      );

  @override
  Widget build(BuildContext context) {
    final otherName = chat.participantNames[_otherUserId] ?? 'Utilisateur';
    final otherAvatar = chat.participantAvatars[_otherUserId];
    final unread = chat.unreadCount[currentUserId] ?? 0;
    final hasUnread = unread > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: 10,
        ),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────
            CachedImage(
              imageUrl: otherAvatar,
              width: 52,
              height: 52,
              borderRadius: AppRadius.circle,
            ),
            const SizedBox(width: 12),
            // ── Text ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherName,
                        style: hasUnread
                            ? AppTextStyles.labelLarge
                            : AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chat.lastMessageAt != null)
                        Text(
                          _formatTime(chat.lastMessageAt!),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? '...',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: hasUnread
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: unread),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
