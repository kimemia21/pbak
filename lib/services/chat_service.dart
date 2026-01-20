import 'package:pbak/models/chat_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Chat Service
/// Handles all chat/messaging related API calls for Nyumba Kumi
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _comms = CommsService.instance;

  /// Get all chat rooms for a member
  /// GET /members/{member_id}/chatrooms
  Future<List<ChatRoom>> getMemberChatRooms(int memberId) async {
    try {
      final response = await _comms.get(ApiEndpoints.memberChatRooms(memberId));

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to ChatRoom
        if (data is List) {
          return data
              .map((json) => ChatRoom.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load chat rooms: $e');
    }
  }

  /// Get messages for a specific chat room
  /// GET /chatrooms/{chat_room_id}/members/{member_id}/messages
  Future<List<ChatMessage>> getChatRoomMessages({
    required int chatRoomId,
    required int memberId,
    int? currentUserId,
  }) async {
    try {
      final response = await _comms.get(
        ApiEndpoints.chatRoomMessages(chatRoomId, memberId),
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to ChatMessage
        if (data is List) {
          return data
              .map((json) => ChatMessage.fromJson(
                    json as Map<String, dynamic>,
                    currentUserId: currentUserId ?? memberId,
                  ))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Send a message to a chat room
  /// POST /chatrooms/messages
  Future<ChatMessage?> sendMessage({
    required int chatRoomId,
    required int memberId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.sendMessage,
        data: {
          'chat_room_id': chatRoomId,
          'member_id': memberId,
          'message': message,
          'message_type': messageType,
        },
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        if (data is Map<String, dynamic>) {
          return ChatMessage.fromJson(data, currentUserId: memberId);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
