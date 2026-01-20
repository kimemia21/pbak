import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/chat_model.dart';
import 'package:pbak/providers/chat_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';

class ChatRoomsScreen extends ConsumerWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chatRoomsAsync = ref.watch(memberChatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nyumba Kumi Chats'),
        elevation: 0,
      ),
      body: chatRoomsAsync.when(
        data: (chatRooms) {
          if (chatRooms.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No Chat Rooms Yet',
              message: 'You haven\'t joined any Nyumba Kumi groups yet. Join a group to start chatting!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(memberChatRoomsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingS),
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                return _ChatRoomTile(chatRoom: chatRoom);
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading chat rooms...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load chat rooms',
          onRetry: () => ref.invalidate(memberChatRoomsProvider),
        ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;

  const _ChatRoomTile({required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = (chatRoom.unreadCount ?? 0) > 0;
    
    // Format last message time
    String? timeText;
    if (chatRoom.lastMessage?.sentAt != null) {
      final now = DateTime.now();
      final messageTime = chatRoom.lastMessage!.sentAt!;
      final diff = now.difference(messageTime);
      
      if (diff.inDays == 0) {
        timeText = DateFormat('HH:mm').format(messageTime);
      } else if (diff.inDays == 1) {
        timeText = 'Yesterday';
      } else if (diff.inDays < 7) {
        timeText = DateFormat('EEE').format(messageTime);
      } else {
        timeText = DateFormat('dd/MM/yy').format(messageTime);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/chat/${chatRoom.chatRoomId}', extra: {
            'name': chatRoom.name,
            'imageUrl': chatRoom.imageUrl,
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingM,
            vertical: AppTheme.paddingM,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              _ChatAvatar(
                name: chatRoom.name,
                imageUrl: chatRoom.imageUrl,
                hasUnread: hasUnread,
              ),
              const SizedBox(width: AppTheme.paddingM),
              
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatRoom.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeText != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hasUnread 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Last message and unread badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatRoom.lastMessage?.message ?? 'No messages yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: hasUnread
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread ? FontWeight.w500 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chatRoom.unreadCount! > 99 
                                  ? '99+' 
                                  : chatRoom.unreadCount.toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Member count
                    if (chatRoom.memberCount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${chatRoom.memberCount} members',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool hasUnread;

  const _ChatAvatar({
    required this.name,
    this.imageUrl,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get initials from name
    final initials = name.split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: hasUnread
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initials,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        if (hasUnread)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
