class ChatbotMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatbotMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  // Para Firebase
  Map<String, dynamic> toMap() {
    return {
      'userMessage': isUser ? message : '',
      'botResponse': !isUser ? message : '',
      'timestamp': timestamp,
    };
  }

  // Desde Firebase
  factory ChatbotMessage.fromMap(Map<String, dynamic> map) {
    final isUserMsg = map['userMessage']?.isNotEmpty ?? false;
    return ChatbotMessage(
      id: map['id'] ?? '',
      message: isUserMsg ? map['userMessage'] : map['botResponse'],
      isUser: isUserMsg,
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
    );
  }
}