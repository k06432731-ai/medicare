import 'package:flutter/material.dart';

enum MessageRole { user, assistant }

class ChatMessageModel {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool isTyping; // indicateur "en cours de frappe"

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isTyping = false,
  });

  factory ChatMessageModel.user(String content) => ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.user,
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatMessageModel.assistant(String content,
          {bool isTyping = false}) =>
      ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: content,
        createdAt: DateTime.now(),
        isTyping: isTyping,
      );

  /// Convertit pour l'API OpenAI
  Map<String, String> toApiMessage() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };

  Color get bubbleColor => role == MessageRole.user
      ? const Color(0xFF6366F1) // indigo patient
      : const Color(0xFFF1F5F9); // gris clair IA
}
