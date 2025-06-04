import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatbot_message.dart';

class ChatConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<ChatbotMessage> messages;

  ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdated,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'messages': messages.map((msg) => msg.toMap()).toList(),
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map, String docId) {
    return ChatConversation(
      id: docId,
      title: map['title'] ?? 'Nueva conversación',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      messages: (map['messages'] as List)
          .map((msg) => ChatbotMessage.fromMap(msg, msg['id'] ?? ''))
          .toList(),
    );
  }

  factory ChatConversation.create() {
    final now = DateTime.now();
    return ChatConversation(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'Nueva conversación',
      createdAt: now,
      lastUpdated: now,
      messages: [],
    );
  }

  ChatConversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<ChatbotMessage>? messages,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messages: messages ?? this.messages,
    );
  }

  ChatConversation addMessage(ChatbotMessage message) {
    return copyWith(
      messages: [...messages, message],
      lastUpdated: DateTime.now(),
    );
  }
}