import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chatbot_message.dart';
import '../models/chat_conversation.dart';
import 'openai_service.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenAIService _openAI = OpenAIService();
  
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
      
      // Usar el campo 'usuario' que contiene el nombre completo
      final nombreUsuario = userData['usuario'];
      if (nombreUsuario != null && nombreUsuario.toString().trim().isNotEmpty) {
        return nombreUsuario.toString();
      }
      
      // Si por alguna razón no hay usuario, usar el valor por defecto
      return 'Jose';
    }
    return 'Jose';
  } catch (e) {
    print('Error obteniendo nombre de usuario: $e');
    return 'Csandoval-dev';
  }
}
  Future<List<Map<String, dynamic>>> getUserHabits(String userId) async {
    try {
      final habitsSnapshot = await _firestore
          .collection('Usuarios')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: false)
          .get();

      List<Map<String, dynamic>> habits = [];
      
      for (var doc in habitsSnapshot.docs) {
        final data = doc.data();
        habits.add({
          'id': doc.id,
          'name': data['name'] ?? 'Hábito sin nombre',
          'description': data['description'] ?? '',
          'category': data['category'] ?? 'General',
          'colorHex': data['colorHex'] ?? '#4285F4',
          'isActive': _isHabitActive(data),
        });
      }

      return habits.where((habit) => habit['isActive'] == true).toList();
    } catch (e) {
      print('Error obteniendo hábitos: $e');
      return [];
    }
  }

  bool _isHabitActive(Map<String, dynamic> habitData) {
    final endDate = habitData['endDate'];
    if (endDate == null) return true;
    
    final endDateTime = (endDate as Timestamp).toDate();
    return DateTime.now().isBefore(endDateTime);
  }

  Future<Map<String, dynamic>> getHabitMetrics(String userId, String habitId) async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      final metricsSnapshot = await _firestore
          .collection('Usuarios')
          .doc(userId)
          .collection('metrics')
          .where('habitId', isEqualTo: habitId)
          .where('date', isGreaterThan: oneWeekAgo)
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      int totalDone = 0;
      int totalMissed = 0;
      
      for (var doc in metricsSnapshot.docs) {
        final data = doc.data();
       totalDone += (data['done'] as int?) ?? 0;
      totalMissed += (data['missed'] as int?) ?? 0;

      }

      final total = totalDone + totalMissed;
      final completionRate = total > 0 ? (totalDone / total * 100).round() : 0;

      return {
        'totalDone': totalDone,
        'totalMissed': totalMissed,
        'completionRate': completionRate,
        'weeklyData': metricsSnapshot.docs.length,
        'lastUpdate': now.toIso8601String(),
      };
    } catch (e) {
      print('Error obteniendo métricas: $e');
      return {
        'totalDone': 0,
        'totalMissed': 0,
        'completionRate': 0,
        'weeklyData': 0,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<ChatConversation> createNewConversation(String userId) async {
    try {
      final habits = await getUserHabits(userId);
      final userName = await getUserName(userId);
      
      String welcomeMessage = "¡Hola $userName! 👋\n\n";
      
      if (habits.isEmpty) {
        welcomeMessage += "Soy tu asistente personal. Para empezar a trabajar juntos, " +
                         "necesitarás agregar algunos hábitos que quieras desarrollar. " +
                         "Una vez que lo hagas, podré ayudarte a darles seguimiento y " +
                         "brindarte consejos personalizados.";
      } else {
        welcomeMessage += "Estos son tus hábitos activos:\n\n";
        for (int i = 0; i < habits.length; i++) {
          final habit = habits[i];
          welcomeMessage += "${i + 1}. ${habit['name']}";
          if (habit['description']?.isNotEmpty ?? false) {
            welcomeMessage += " - ${habit['description']}";
          }
          welcomeMessage += "\n";
        }
        welcomeMessage += "\n¿Sobre cuál hábito te gustaría conversar? " +
                         "Puedes escribir el nombre o número del hábito.";
      }
      final newConversation = ChatConversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Nueva conversación',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        messages: [
          ChatbotMessage(
            id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
            message: welcomeMessage,
            isUser: false,
            timestamp: DateTime.now(),
          )
        ],
      );

      await _getConversationsRef(userId)
          .doc(newConversation.id)
          .set(newConversation.toMap());

      return newConversation;
    } catch (e) {
      print('Error creando nueva conversación: $e');
      return ChatConversation.create();
    }
  }

  Future<ChatbotMessage> sendMessage(
    String userId,
    String message, {
    String? conversationId,
  }) async {
    try {
      ChatConversation conversation;
      if (conversationId != null) {
        conversation = await getConversation(userId, conversationId);
      } else {
        conversation = await createNewConversation(userId);
      }

      final userMessage = ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      if (conversation.messages.length <= 1) {
        conversation = conversation.copyWith(
          title: _generateConversationTitle(message),
        );
      }

      final context = await _prepareHabitContext(userId, message, conversation);
      
      final botResponse = await _openAI.sendMessage(
        userMessage: message,
        userContext: context,
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
        message: 'Lo siento, hubo un error. ¿Podrías intentar de nuevo?',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<Map<String, dynamic>> _prepareHabitContext(
    String userId, 
    String userMessage, 
    ChatConversation conversation
  ) async {
    final habits = await getUserHabits(userId);
    final userName = await getUserName(userId);
    
    String? selectedHabitId;
    Map<String, dynamic>? selectedHabitData;
    
    final userMessageLower = userMessage.toLowerCase();
    
    // Primero intentar encontrar por número
    final numberMatch = RegExp(r'^(\d+)').firstMatch(userMessageLower);
    if (numberMatch != null) {
      final number = int.parse(numberMatch.group(1)!) - 1;
      if (number >= 0 && number < habits.length) {
        selectedHabitId = habits[number]['id'];
        selectedHabitData = habits[number];
      }
    }
    
    // Si no se encontró por número, buscar por nombre
    if (selectedHabitId == null) {
      for (var habit in habits) {
        final habitName = habit['name'].toString().toLowerCase();
        if (userMessageLower.contains(habitName)) {
          selectedHabitId = habit['id'];
          selectedHabitData = habit;
          break;
        }
      }
    }

    Map<String, dynamic> context = {
      'userName': userName,
      'totalHabits': habits.length,
      'habitsList': habits,
      'currentHabit': selectedHabitData,
      'conversationHistory': conversation.messages.take(5).map((msg) => {
        'isUser': msg.isUser,
        'message': msg.message,
      }).toList(),
    };

    if (selectedHabitId != null) {
      final metrics = await getHabitMetrics(userId, selectedHabitId);
      context['habitMetrics'] = metrics;
      context['focusedHabitId'] = selectedHabitId;
    }

    return context;
  }

  String _generateConversationTitle(String message) {
    if (message.length <= 30) {
      return message;
    }
    return message.substring(0, 27) + '...';
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
        return await createNewConversation(userId);
      }

      return ChatConversation.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error obteniendo conversación: $e');
      return await createNewConversation(userId);
    }
  }

  Stream<List<ChatConversation>> getConversations(String userId) {
    return _getConversationsRef(userId)
        .orderBy('lastUpdated', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatConversation.fromMap(doc.data(), doc.id);
      }).toList();
    });
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

  Future<void> clearAllConversations(String userId) async {
    try {
      final batch = _firestore.batch();
      final conversations = await _getConversationsRef(userId).get();

      for (final doc in conversations.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error limpiando conversaciones: $e');
    }
  }
}