import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chatbot_message.dart';
import '../models/chat_conversation.dart';
import 'openai_service.dart';
import 'analytics_service.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenAIService _openAI = OpenAIService();
  final AnalyticsService _analytics = AnalyticsService();
  
  CollectionReference<Map<String, dynamic>> _getConversationsRef(String userId) {
    return _firestore
        .collection('Usuarios')
        .doc(userId)
        .collection('conversations');
  }

  Future<String> getUserName(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('Usuarios')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['nombre'] ?? 
               userData['usuario'] ?? 
               userData['email']?.split('@')[0] ?? 
               'Usuario';
      }
      return 'Usuario';
    } catch (e) {
      print('Error obteniendo nombre de usuario: $e');
      return 'Usuario';
    }
  }

  Future<ChatConversation> getCurrentConversation(String userId) async {
    try {
      final conversationsRef = _getConversationsRef(userId);
      final snapshot = await conversationsRef
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        final newConversation = ChatConversation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Nueva conversación',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          messages: [],
        );
        await conversationsRef.doc(newConversation.id).set(newConversation.toMap());
        return newConversation;
      }

      return ChatConversation.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('Error obteniendo conversación actual: $e');
      return ChatConversation.create();
    }
  }

  Future<ChatbotMessage> sendMessage(
    String userId,
    String message, {
    String? conversationId,
  }) async {
    try {
      final userName = await getUserName(userId);
      
      ChatConversation conversation;
      if (conversationId != null) {
        conversation = await getConversation(userId, conversationId);
      } else {
        conversation = await getCurrentConversation(userId);
      }

      final userMessage = ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      if (conversation.messages.isEmpty) {
        conversation = conversation.copyWith(
          title: _generateConversationTitle(message),
        );
      }

      final userContext = await _analytics.getUserContext(userId);
      userContext['userName'] = userName;

      final botResponse = await _openAI.sendMessage(
        userMessage: message,
        userContext: userContext,
      );
      
      final botMessage = ChatbotMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_bot',
        message: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      conversation = conversation
          .addMessage(userMessage)
          .addMessage(botMessage);
      
      await _getConversationsRef(userId)
          .doc(conversation.id)
          .set(conversation.toMap());
      
      return botMessage;
    } catch (e) {
      print('Error en ChatbotService: $e');
      return ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: 'Lo siento, no pude procesar tu mensaje. ¿Podrías intentar de nuevo?',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  String _generateConversationTitle(String message) {
    if (message.length <= 40) {
      return message;
    }
    final endOfSentence = message.indexOf('.');
    if (endOfSentence > 0 && endOfSentence <= 40) {
      return message.substring(0, endOfSentence);
    }
    return message.substring(0, 37) + '...';
  }

  Future<ChatConversation> getConversation(
    String userId,
    String conversationId,
  ) async {
    try {
      final doc = await _getConversationsRef(userId)
          .doc(conversationId)
          .get();

      if (!doc.exists) {
        throw Exception('Conversación no encontrada');
      }

      return ChatConversation.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error obteniendo conversación: $e');
      return ChatConversation.create();
    }
  }

  Stream<List<ChatConversation>> getConversations(String userId) {
    return _getConversationsRef(userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatConversation.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> clearChatHistory(String userId) async {
    try {
      final batch = _firestore.batch();
      final conversationsDocs = await _getConversationsRef(userId).get();

      for (final doc in conversationsDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error limpiando historial: $e');
    }
  }

  Future<String?> generateProactiveInsight(String userId) async {
    try {
      final context = await _analytics.getUserContext(userId);
      final userName = await getUserName(userId);
      
      if (context['totalHabits'] == 0) return null;
      
      final completionRate = context['weeklyCompletionRate'] as double;
      final strugglingHabits = context['strugglingHabits'] as List<String>;
      final patterns = context['patterns'] as Map<String, dynamic>;
      
      String proactiveMessage = '';
      
      if (completionRate < 30) {
        proactiveMessage = '¡Hola $userName! 👋 He notado que esta semana has tenido algunos desafíos con tus hábitos (${completionRate.toStringAsFixed(0)}% de cumplimiento). ¿Te gustaría que conversemos sobre cómo mejorar?';
      } else if (strugglingHabits.isNotEmpty) {
        proactiveMessage = 'Hola $userName 😊 Veo que "${strugglingHabits.first}" te está costando un poco. ¿Quieres algunos consejos personalizados para hacer que sea más fácil?';
      } else if (completionRate > 80) {
        proactiveMessage = '¡Increíble trabajo esta semana, $userName! 🎉 Tienes un ${completionRate.toStringAsFixed(0)}% de cumplimiento. ¿Te sientes listo para un nuevo desafío?';
      } else if (patterns['declining'] == true) {
        proactiveMessage = '$userName, he notado una tendencia a la baja en algunos de tus hábitos. 📉 ¿Qué tal si revisamos tu estrategia juntos?';
      } else if (patterns['improving'] == true) {
        proactiveMessage = '¡Excelente progreso, $userName! 📈 Tus hábitos están mejorando. ¿Quieres saber qué está funcionando mejor para ti?';
      }
      
      return proactiveMessage.isNotEmpty ? proactiveMessage : null;
    } catch (e) {
      print('Error generando insight proactivo: $e');
      return null;
    }
  }
// Agregar este nuevo método al ChatbotService
Future<ChatConversation> createNewConversation(String userId) async {
  try {
    final conversationsRef = _getConversationsRef(userId);
    final newConversation = ChatConversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Nueva conversación',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      messages: [],
    );

    await conversationsRef
        .doc(newConversation.id)
        .set(newConversation.toMap());

    return newConversation;
  } catch (e) {
    print('Error creando nueva conversación: $e');
    return ChatConversation.create();
  }
}

Future<void> deleteConversation(String userId, String conversationId) async {
  try {
    await _getConversationsRef(userId)
        .doc(conversationId)
        .delete();
  } catch (e) {
    print('Error eliminando conversación: $e');
  }
}
  Future<Map<String, dynamic>> getQuickStats(String userId) async {
    try {
      final context = await _analytics.getUserContext(userId);
      return {
        'totalHabits': context['totalHabits'] ?? 0,
        'completionRate': context['weeklyCompletionRate'] ?? 0.0,
        'bestHabits': context['bestHabits'] ?? [],
        'strugglingHabits': context['strugglingHabits'] ?? [],
        'preferredTime': context['patterns']?['preferredTime'] ?? 'No identificado',
      };
    } catch (e) {
      print('Error obteniendo estadísticas rápidas: $e');
      return {};
    }
  }
}