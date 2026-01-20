import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/chat_model.dart';
import 'package:pbak/services/chat_service.dart';
import 'package:pbak/providers/auth_provider.dart';

// Chat service provider
final chatServiceProvider = Provider((ref) => ChatService());

/// Provider for member's chat rooms
final memberChatRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;

  if (user != null) {
    try {
      final chatService = ref.read(chatServiceProvider);
      return await chatService.getMemberChatRooms(user.memberId);
    } catch (e) {
      print('Error loading chat rooms: $e');
      return [];
    }
  }
  return [];
});

/// Provider for messages in a specific chat room
final chatRoomMessagesProvider = FutureProvider.family<List<ChatMessage>, int>((ref, chatRoomId) async {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;

  if (user != null) {
    try {
      final chatService = ref.read(chatServiceProvider);
      return await chatService.getChatRoomMessages(
        chatRoomId: chatRoomId,
        memberId: user.memberId,
        currentUserId: user.memberId,
      );
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }
  return [];
});

/// State for active chat
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// Notifier for managing chat state and sending messages
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final int chatRoomId;
  final int memberId;

  ChatNotifier({
    required ChatService chatService,
    required this.chatRoomId,
    required this.memberId,
  })  : _chatService = chatService,
        super(ChatState()) {
    loadMessages();
  }

  /// Load messages for the chat room
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _chatService.getChatRoomMessages(
        chatRoomId: chatRoomId,
        memberId: memberId,
        currentUserId: memberId,
      );

      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: $e',
      );
    }
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    await loadMessages();
  }

  /// Send a message
  Future<bool> sendMessage(String message) async {
    if (message.trim().isEmpty) return false;

    state = state.copyWith(isSending: true, error: null);

    try {
      final sentMessage = await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        memberId: memberId,
        message: message.trim(),
      );

      if (sentMessage != null) {
        // Add the new message to the list
        final updatedMessages = [...state.messages, sentMessage];
        state = state.copyWith(
          messages: updatedMessages,
          isSending: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isSending: false,
          error: 'Failed to send message',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send message: $e',
      );
      return false;
    }
  }

  /// Add a message locally (for optimistic updates)
  void addLocalMessage(ChatMessage message) {
    final updatedMessages = [...state.messages, message];
    state = state.copyWith(messages: updatedMessages);
  }
}

/// Provider for chat notifier - needs to be created per chat room
final chatNotifierProvider = StateNotifierProvider.family<ChatNotifier, ChatState, int>(
  (ref, chatRoomId) {
    final chatService = ref.read(chatServiceProvider);
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    return ChatNotifier(
      chatService: chatService,
      chatRoomId: chatRoomId,
      memberId: user?.memberId ?? 0,
    );
  },
);
