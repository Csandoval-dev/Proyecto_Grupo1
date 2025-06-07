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
               (userData['email'] as String?)?.split('@')[0] ??
               'Usuario';
      }
      return 'Usuario';
    } catch (e) {
      print('Error obteniendo nombre de usuario: $e');
      return 'Usuario';
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
          'createdAt': data['createdAt'],
          'schedule': data['schedule'] ?? {},
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
      List<Map<String, dynamic>> dailyData = [];

      for (var doc in metricsSnapshot.docs) {
        final data = doc.data();
        totalDone += (data['done'] as int?) ?? 0;
        totalMissed += (data['missed'] as int?) ?? 0;
        
        dailyData.add({
          'date': (data['date'] as Timestamp).toDate().toIso8601String(),
          'done': data['done'] ?? 0,
          'missed': data['missed'] ?? 0,
          'notes': data['notes'] ?? '',
        });
      }

      final total = totalDone + totalMissed;
      final completionRate = total > 0 ? (totalDone / total * 100).round() : 0;

      return {
        'totalDone': totalDone,
        'totalMissed': totalMissed,
        'completionRate': completionRate,
        'weeklyData': dailyData,
        'lastUpdate': now.toIso8601String(),
        'hasData': dailyData.isNotEmpty,
      };
    } catch (e) {
      print('Error obteniendo métricas: $e');
      return {
        'totalDone': 0,
        'totalMissed': 0,
        'completionRate': 0,
        'weeklyData': [],
        'lastUpdate': DateTime.now().toIso8601String(),
        'hasData': false,
      };
    }
  }

  Future<ChatConversation> createNewConversation(String userId) async {
    try {
      final habits = await getUserHabits(userId);
      final userName = await getUserName(userId);
      final userContext = await _analytics.getUserContext(userId);

      String welcomeMessage = "¡Hola $userName! 👋\n\n";

      if (habits.isEmpty) {
        welcomeMessage += "Soy tu asistente personal de hábitos. Para empezar "
                         "necesitarás agregar algunos hábitos que quieras desarrollar. "
                         "Una vez que lo hagas, podré ayudarte a darles seguimiento y "
                         "brindarte consejos personalizados basados en tus datos.";
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
        welcomeMessage += "\n¿Sobre cuál hábito te gustaría conversar? "
                         "Puedes seleccionar por número o nombre.";
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

    String? selectedHabitId = await _getSelectedHabitFromConversation(
      conversation,
      habits
    );

    if (selectedHabitId == null) {
      final habitMatch = _findHabitInMessage(userMessage, habits);
      if (habitMatch != null) {
        selectedHabitId = habitMatch['id'];
      }
    }

    Map<String, dynamic>? selectedHabitData;
    if (selectedHabitId != null) {
      try {
        selectedHabitData = habits.firstWhere(
          (h) => h['id'] == selectedHabitId,
        );
      } catch (e) {
        selectedHabitData = null;
      }
    }

    final conversationContext = _extractConversationContext(conversation);

    Map<String, dynamic> context = {
      'userName': userName,
      'totalHabits': habits.length,
      'habitsList': habits,
      'currentHabit': selectedHabitData,
      'conversationHistory': conversation.messages
          .take(10)
          .map((msg) => {
            'isUser': msg.isUser,
            'message': msg.message,
            'timestamp': msg.timestamp.toIso8601String(),
          })
          .toList(),
      'previousContext': conversationContext,
    };

    if (selectedHabitId != null) {
      final metrics = await getHabitMetrics(userId, selectedHabitId);
      context['habitMetrics'] = metrics;
      context['focusedHabitId'] = selectedHabitId;
    }

    return context;
  }

  Future<String?> _getSelectedHabitFromConversation(
    ChatConversation conversation,
    List<Map<String, dynamic>> habits
  ) async {
    final recentMessages = conversation.messages.reversed.take(5).toList();
    
    for (var msg in recentMessages) {
      if (!msg.isUser) {
        for (var habit in habits) {
          if (msg.message.toLowerCase().contains(
            'hábito "${habit['name'].toLowerCase()}"'
          )) {
            return habit['id'];
          }
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _findHabitInMessage(
    String message,
    List<Map<String, dynamic>> habits
  ) {
    final messageLower = message.toLowerCase();
    
    final numberMatch = RegExp(r'^(\d+)').firstMatch(messageLower);
    if (numberMatch != null) {
      final number = int.parse(numberMatch.group(1)!) - 1;
      if (number >= 0 && number < habits.length) {
        return habits[number];
      }
    }

    try {
      return habits.firstWhere(
        (habit) => messageLower.contains(
          habit['name'].toString().toLowerCase()
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _extractConversationContext(ChatConversation conversation) {
    final lastBotMessages = conversation.messages
        .where((msg) => !msg.isUser)
        .take(3)
        .toList();

    return {
      'lastTopic': _identifyLastTopic(lastBotMessages),
      'lastSuggestion': _findLastSuggestion(lastBotMessages),
      'conversationFlow': _determineConversationFlow(conversation.messages),
      'selectedOptions': _extractSelectedOptions(conversation.messages),
    };
  }

  String? _identifyLastTopic(List<ChatbotMessage> messages) {
    if (messages.isEmpty) return null;
    
    final lastMessage = messages.first.message;
    if (lastMessage.contains('hábito')) {
      final habitMatch = RegExp(r'hábito de ([\w\s]+)').firstMatch(lastMessage);
      return habitMatch?.group(1);
    }
    return null;
  }

  String? _findLastSuggestion(List<ChatbotMessage> messages) {
    if (messages.isEmpty) return null;

    for (var msg in messages) {
      final suggestions = RegExp(r'\[(.*?)\]')
          .allMatches(msg.message)
          .map((m) => m.group(1))
          .toList();
      
      if (suggestions.isNotEmpty) {
        return suggestions.join(', ');
      }
    }
    return null;
  }

  String _determineConversationFlow(List<ChatbotMessage> messages) {
    if (messages.length <= 1) return 'inicial';
    
    final recentMessages = messages.reversed.take(3).toList();
    ChatbotMessage? lastUserMessage;
    
    try {
      lastUserMessage = recentMessages.firstWhere((msg) => msg.isUser);
    } catch (e) {
      return 'inicial';
    }

    final message = lastUserMessage.message.toLowerCase();
    
    if (message.contains('ayuda') || message.contains('problema')) {
      return 'solución_problema';
    } else if (message.contains('cómo') || message.contains('qué')) {
      return 'información';
    } else if (message.contains('gracias') || message.contains('entiendo')) {
      return 'cierre';
    }

    return 'seguimiento';
  }

  List<String> _extractSelectedOptions(List<ChatbotMessage> messages) {
    final selectedOptions = <String>[];
    final recentMessages = messages.reversed.take(5).toList();

    for (var msg in recentMessages) {
      if (msg.isUser) {
        final userChoice = msg.message.replaceAll(RegExp(r'[\[\]]'), '').trim();
        if (userChoice.isNotEmpty) {
          selectedOptions.add(userChoice);
        }
      }
    }

    return selectedOptions;
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

  String _generateConversationTitle(String message) {
    if (message.length <= 30) {
      return message;
    }
    return '${message.substring(0, 27)}...';
  }
}