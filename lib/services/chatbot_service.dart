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

      final activeHabits = habits.where((habit) => habit['isActive'] == true).toList();
      return activeHabits;
    } catch (e) {
      print('❌ Error obteniendo hábitos: $e');
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
      final metricsSnapshot = await _firestore
          .collection('Usuarios')
          .doc(userId)
          .collection('metrics')
          .where('habitId', isEqualTo: habitId)
          .get();

      int totalDone = 0;
      int totalMissed = 0;
      List<Map<String, dynamic>> dailyData = [];

      final sortedDocs = metricsSnapshot.docs
        ..sort((a, b) {
          final aDate = (a.data()['startDate'] as Timestamp).toDate();
          final bDate = (b.data()['startDate'] as Timestamp).toDate();
          return bDate.compareTo(aDate);
        });

      final recentDocs = sortedDocs.take(7);

      for (var doc in recentDocs) {
        final data = doc.data();
        final date = (data['startDate'] as Timestamp).toDate();
        final done = (data['countDone'] as int?) ?? 0;
        final missed = (data['countMissed'] as int?) ?? 0;
        totalDone += done;
        totalMissed += missed;
       dailyData.add({
  'date': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
  'done': done,
  'missed': missed,
  'notes': data['notes'] ?? '',
  'dayOfWeek': date.weekday,
});
      }

      final total = totalDone + totalMissed;
      final completionRate = total > 0 ? (totalDone / total * 100).round() : 0;

      // No recomendaciones predefinidas, solo métricas y patrones reales
      final patterns = _analyzePatterns(dailyData);

      return {
        'totalDone': totalDone,
        'totalMissed': totalMissed,
        'completionRate': completionRate,
        'weeklyData': dailyData,
        'patterns': patterns,
        'lastUpdate': DateTime.now().toIso8601String(),
        'hasData': dailyData.isNotEmpty,
      };
    } catch (e) {
      print('❌ Error obteniendo métricas: $e');
      return {
        'totalDone': 0,
        'totalMissed': 0,
        'completionRate': 0,
        'weeklyData': [],
        'patterns': _getEmptyPatterns(),
        'lastUpdate': DateTime.now().toIso8601String(),
        'hasData': false,
      };
    }
  }

  Map<String, dynamic> _analyzePatterns(List<Map<String, dynamic>> dailyData) {
    if (dailyData.isEmpty) return _getEmptyPatterns();

    Map<int, int> successByDay = {};
    Map<int, int> totalByDay = {};

    for (var day in dailyData) {
      final dayOfWeek = DateTime.parse(day['date']).weekday;
      final done = day['done'] as int;
      final total = done + (day['missed'] as int);
      successByDay[dayOfWeek] = (successByDay[dayOfWeek] ?? 0) + done;
      totalByDay[dayOfWeek] = (totalByDay[dayOfWeek] ?? 0) + total;
    }

    int bestDay = 1;
    int worstDay = 1;
    double bestRate = 0;
    double worstRate = 1;

    successByDay.forEach((day, success) {
      final total = totalByDay[day] ?? 1;
      final rate = success / total;
      if (rate > bestRate) {
        bestRate = rate;
        bestDay = day;
      }
      if (rate < worstRate) {
        worstRate = rate;
        worstDay = day;
      }
    });

    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    for (var day in dailyData) {
      if (day['done'] > 0) {
        tempStreak++;
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }
    currentStreak = tempStreak;

    return {
      'bestDay': _getDayName(bestDay),
      'bestDayRate': (bestRate * 100).round(),
      'worstDay': _getDayName(worstDay),
      'worstDayRate': (worstRate * 100).round(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      // Recomendaciones removidas: solo datos reales
      'recommendations': [],
    };
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Desconocido';
    }
  }

  Map<String, dynamic> _getEmptyPatterns() {
    return {
      'bestDay': 'Sin datos',
      'bestDayRate': 0,
      'worstDay': 'Sin datos',
      'worstDayRate': 0,
      'currentStreak': 0,
      'bestStreak': 0,
      'recommendations': [],
    };
  }

  Future<void> setSelectedHabitForConversation(String userId, String conversationId, String habitId) async {
    try {
      await _getConversationsRef(userId)
          .doc(conversationId)
          .update({'selectedHabitId': habitId, 'lastUpdated': DateTime.now()});
    } catch (e) {
      print('Error actualizando selectedHabitId: $e');
    }
  }

  Future<String?> getSelectedHabitId(String userId, ChatConversation conversation, List<Map<String, dynamic>> habits) async {
    final doc = await _getConversationsRef(userId).doc(conversation.id).get();
    if (doc.exists && doc.data()!.containsKey('selectedHabitId')) {
      final id = doc.data()!['selectedHabitId'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
    }
    final recentMessages = conversation.messages.reversed.take(10).toList();
    for (var msg in recentMessages) {
      if (msg.isUser) {
        final numberMatch = RegExp(r'^(\d+)').firstMatch(msg.message);
        if (numberMatch != null) {
          final number = int.parse(numberMatch.group(1)!)-1;
          if (number >= 0 && number < habits.length) return habits[number]['id'];
        }
        try {
          final habit = habits.firstWhere((h) => msg.message.toLowerCase().contains(h['name'].toString().toLowerCase()));
          return habit['id'];
        } catch (_) {}
      }
    }
    return null;
  }

  Future<ChatConversation> createNewConversation(String userId) async {
    try {
      final habits = await getUserHabits(userId);
      final userName = await getUserName(userId);

      String welcomeMessage = "¡Hola $userName! 👋\n\n";

      if (habits.isEmpty) {
        welcomeMessage += "Soy tu asistente personal de hábitos. Para empezar necesitas agregar algunos hábitos que quieras desarrollar. Una vez que lo hagas, podré ayudarte a darles seguimiento y brindarte consejos personalizados basados en tus datos.";
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
        welcomeMessage += "\n¿Sobre cuál hábito te gustaría conversar? Puedes seleccionar por número o nombre.";
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

      // Solo mostrar el resumen general si el usuario lo pide explícitamente
      bool userWantsResumen = message.toLowerCase().contains('ver resumen') ||
                              message.toLowerCase().contains('ver hábitos');

      if (userWantsResumen) {
        final habits = await getUserHabits(userId);
        String resumen = "Estos son tus hábitos activos:\n\n";
        for (int i = 0; i < habits.length; i++) {
          final habit = habits[i];
          resumen += "${i + 1}. ${habit['name']}";
          if (habit['description']?.isNotEmpty ?? false) {
            resumen += " - ${habit['description']}";
          }
          resumen += "\n";
        }
        resumen += "\n¿Sobre cuál hábito te gustaría conversar? Puedes seleccionar por número o nombre.";
        final botMessage = ChatbotMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_bot',
          message: resumen,
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
      }

      final context = await _prepareHabitContext(userId, message, conversation);

      if (context['focusedHabitId'] != null && conversationId != null) {
        await setSelectedHabitForConversation(userId, conversationId, context['focusedHabitId']);
      }

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

    String? selectedHabitId = await getSelectedHabitId(userId, conversation, habits);

    final habitMatch = _findHabitInMessage(userMessage, habits);
    if (habitMatch != null && habitMatch['id'] != selectedHabitId) {
      selectedHabitId = habitMatch['id'];
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
          .take(15)
          .map((msg) => {
            'isUser': msg.isUser,
            'message': msg.message,
            'timestamp': msg.timestamp.toIso8601String(),
          })
          .toList(),
      'previousContext': conversationContext,
      'lastUserMessage': userMessage,
    };

    if (selectedHabitId != null) {
      final metrics = await getHabitMetrics(userId, selectedHabitId);
      context['habitMetrics'] = metrics;
      context['focusedHabitId'] = selectedHabitId;
    }

    return context;
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
        .take(5)
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
    final recentMessages = messages.reversed.take(10).toList();
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