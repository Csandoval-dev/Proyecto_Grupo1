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
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp,
    };
  }

  // Desde Firebase
  factory ChatbotMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatbotMessage(
      id: docId,
      message: map['message'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  // Crear copia con modificaciones
  ChatbotMessage copyWith({
    String? id,
    String? message,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatbotMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Para debugging
  @override
  String toString() {
    return 'ChatbotMessage(id: $id, message: $message, isUser: $isUser, timestamp: $timestamp)';
  }

  // Comparación
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatbotMessage &&
        other.id == id &&
        other.message == message &&
        other.isUser == isUser &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        message.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode;
  }
}