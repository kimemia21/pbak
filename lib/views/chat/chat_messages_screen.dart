import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/chat_model.dart';
import 'package:pbak/providers/chat_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/widgets/loading_widget.dart';

class ChatMessagesScreen extends ConsumerStatefulWidget {
  final int chatRoomId;
  final String? chatRoomName;
  final String? chatRoomImageUrl;

  const ChatMessagesScreen({
    super.key,
    required this.chatRoomId,
    this.chatRoomName,
    this.chatRoomImageUrl,
  });

  @override
  ConsumerState<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends ConsumerState<ChatMessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    
    final success = await ref
        .read(chatNotifierProvider(widget.chatRoomId).notifier)
        .sendMessage(message);

    if (success) {
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatNotifierProvider(widget.chatRoomId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState.valueOrNull?.memberId ?? 0;

    // Scroll to bottom when messages load
    ref.listen(chatNotifierProvider(widget.chatRoomId), (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom(animated: false);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar
            _ChatRoomAvatar(
              name: widget.chatRoomName ?? 'Chat',
              imageUrl: widget.chatRoomImageUrl,
              size: 40,
            ),
            const SizedBox(width: AppTheme.paddingM),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoomName ?? 'Chat Room',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Nyumba Kumi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(chatNotifierProvider(widget.chatRoomId).notifier).refreshMessages();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const LoadingWidget(message: 'Loading messages...')
                : chatState.messages.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildMessagesList(chatState.messages, currentUserId, theme),
          ),

          // Error banner
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingS),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      ref.read(chatNotifierProvider(widget.chatRoomId).notifier).refreshMessages();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Message input
          _buildMessageInput(theme, chatState.isSending),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.paddingM),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to send a message!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages, int currentUserId, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingM,
        vertical: AppTheme.paddingS,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.senderId == currentUserId;
        
        // Check if we should show date separator
        bool showDateSeparator = false;
        if (index == 0) {
          showDateSeparator = true;
        } else {
          final previousMessage = messages[index - 1];
          if (message.sentAt != null && previousMessage.sentAt != null) {
            final currentDate = DateTime(
              message.sentAt!.year,
              message.sentAt!.month,
              message.sentAt!.day,
            );
            final previousDate = DateTime(
              previousMessage.sentAt!.year,
              previousMessage.sentAt!.month,
              previousMessage.sentAt!.day,
            );
            showDateSeparator = currentDate != previousDate;
          }
        }

        // Check if we should show sender name (for group chats)
        bool showSenderName = !isMine;
        if (showSenderName && index > 0) {
          final previousMessage = messages[index - 1];
          if (previousMessage.senderId == message.senderId) {
            showSenderName = false;
          }
        }

        return Column(
          children: [
            if (showDateSeparator)
              _DateSeparator(date: message.sentAt ?? DateTime.now()),
            _MessageBubble(
              message: message,
              isMine: isMine,
              showSenderName: showSenderName,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme, bool isSending) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.paddingM,
        AppTheme.paddingS,
        AppTheme.paddingS,
        MediaQuery.of(context).padding.bottom + AppTheme.paddingS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingM,
                    vertical: AppTheme.paddingM,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.paddingS),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isSending ? null : _sendMessage,
              icon: isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: theme.colorScheme.onPrimary,
                    ),
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      dateText = DateFormat('EEEE').format(date);
    } else {
      dateText = DateFormat('MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingM),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showSenderName;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final timeText = message.sentAt != null
        ? DateFormat('HH:mm').format(message.sentAt!)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            // Sender avatar for others
            if (showSenderName)
              _SenderAvatar(
                name: message.senderName ?? 'User',
                imageUrl: message.senderAvatar,
              )
            else
              const SizedBox(width: 36),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name
                  if (showSenderName && !isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 2),
                      child: Text(
                        message.senderName ?? 'Unknown',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  
                  // Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isMine
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isMine
                                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                                    : theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead == true
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 14,
                                color: message.isRead == true
                                    ? Colors.lightBlueAccent
                                    : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _SenderAvatar({
    required this.name,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initial,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}

class _ChatRoomAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const _ChatRoomAvatar({
    required this.name,
    this.imageUrl,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: theme.textTheme.labelMedium?.copyWith(
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
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
