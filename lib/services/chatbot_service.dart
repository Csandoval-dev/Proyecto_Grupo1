import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chatbot_message.dart';
import 'openai_service.dart';
import 'analytics_service.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenAIService _openAI = OpenAIService();
  final AnalyticsService _analytics = AnalyticsService();

  // Enviar mensaje y obtener respuesta
  Future<ChatbotMessage> sendMessage(String userId, String message) async {
    try {
      // 1. Obtener contexto del usuario
      final userContext = await _analytics.getUserContext(userId);
      
      // 2. Enviar a OpenAI
      final botResponse = await _openAI.sendMessage(
        userMessage: message,
        userContext: userContext,
      );
      
      // 3. Guardar conversación en Firebase
      await _saveConversation(userId, message, botResponse);
      
      // 4. Retornar respuesta del bot
      return ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
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

  // Obtener historial de conversaciones
  Stream<List<ChatbotMessage>> getChatHistory(String userId) {
    return _firestore
        .collection('usuarios') // Cambiado de 'users' a 'usuarios'
        .doc(userId)
        .collection('chatbotHistory')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      List<ChatbotMessage> messages = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Mensaje del usuario
        if (data['userMessage']?.isNotEmpty == true) {
          messages.add(ChatbotMessage(
            id: '${doc.id}_user',
            message: data['userMessage'],
            isUser: true,
            timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
          ));
        }
        
        // Respuesta del bot
        if (data['botResponse']?.isNotEmpty == true) {
          messages.add(ChatbotMessage(
            id: '${doc.id}_bot',
            message: data['botResponse'],
            isUser: false,
            timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
          ));
        }
      }
      
      return messages;
    });
  }

  // Guardar conversación en Firebase
  Future<void> _saveConversation(String userId, String userMessage, String botResponse) async {
    await _firestore
        .collection('usuarios') // Cambiado de 'users' a 'usuarios'
        .doc(userId)
        .collection('chatbotHistory')
        .add({
      'userMessage': userMessage,
      'botResponse': botResponse,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Generar análisis proactivo (para notificaciones automáticas)
  Future<String?> generateProactiveInsight(String userId) async {
    try {
      final context = await _analytics.getUserContext(userId);
      
      // Solo generar insight si hay datos suficientes
      if (context['totalMetrics'] == 0) return null;
      
      final completionRate = context['weeklyCompletionRate'] as double;
      final strugglingHabits = context['strugglingHabits'] as List<String>;
      
      String proactiveMessage = '';
      
      if (completionRate < 30) {
        proactiveMessage = '¡Hola! He notado que esta semana has tenido algunos desafíos con tus hábitos. ¿Te gustaría que conversemos sobre cómo mejorar?';
      } else if (strugglingHabits.isNotEmpty) {
        proactiveMessage = 'Veo que ${strugglingHabits.first} te está costando un poco. ¿Quieres algunos consejos para hacer que sea más fácil?';
      } else if (completionRate > 80) {
        proactiveMessage = '¡Increíble trabajo esta semana! Tienes un ${completionRate.toStringAsFixed(0)}% de cumplimiento. ¿Te sientes listo para un nuevo desafío?';
      }
      
      return proactiveMessage.isNotEmpty ? proactiveMessage : null;
    } catch (e) {
      print('Error generando insight proactivo: $e');
      return null;
    }
  }
}