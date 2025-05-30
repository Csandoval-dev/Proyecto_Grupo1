import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserContext(String userId) async {
    try {
      // Obtener información del usuario
      final userDoc = await _firestore
          .collection('usuarios') 
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return _getDefaultContext();
      }

      final userData = userDoc.data()!;
      final userName = userData['usuario'] ?? 'Usuario';

      // Obtener hábitos del usuario
      final habitsSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('habits')
          .get();

      // Obtener métricas de la última semana
      final metricsSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('metrics')
          .where('startDate', isGreaterThan: _getWeekAgo())
          .get();

      final analysisResult = _analyzeUserData(habitsSnapshot.docs, metricsSnapshot.docs);
      
      // Agregar información del usuario
      analysisResult['userName'] = userName;
      
      return analysisResult;
    } catch (e) {
      print('Error al obtener contexto del usuario: $e');
      return _getDefaultContext();
    }
  }

  Map<String, dynamic> _analyzeUserData(
    List<QueryDocumentSnapshot> habits,
    List<QueryDocumentSnapshot> metrics,
  ) {
    final activeHabits = habits.where((h) => h.data() != null).toList();
    
    // Calcular tasa de cumplimiento general
    double totalCompletion = 0;
    List<String> strugglingHabits = [];
    List<String> bestHabits = [];

    for (final metric in metrics) {
      final data = metric.data() as Map<String, dynamic>;
      final done = data['countDone'] ?? 0;
      final missed = data['countMissed'] ?? 0;
      final total = done + missed;
      
      if (total > 0) {
        final completionRate = (done / total) * 100;
        totalCompletion += completionRate;

        // Encontrar el hábito correspondiente
        final habitId = data['habitId'];
        final habit = activeHabits.where((h) => h.id == habitId).firstOrNull;
        
        if (habit != null) {
          final habitName = habit.data() as Map<String, dynamic>;
          final name = habitName['name'] ?? 'Hábito';
          
          if (completionRate < 50) {
            strugglingHabits.add(name);
          } else if (completionRate > 80) {
            bestHabits.add(name);
          }
        }
      }
    }

    final averageCompletion = metrics.isNotEmpty ? totalCompletion / metrics.length : 0;

    return {
      'totalHabits': activeHabits.length,
      'weeklyCompletionRate': averageCompletion,
      'strugglingHabits': strugglingHabits,
      'bestHabits': bestHabits,
      'totalMetrics': metrics.length,
    };
  }

  Map<String, dynamic> _getDefaultContext() {
    return {
      'userName': 'Usuario',
      'totalHabits': 0,
      'weeklyCompletionRate': 0.0,
      'strugglingHabits': <String>[],
      'bestHabits': <String>[],
      'totalMetrics': 0,
    };
  }

  DateTime _getWeekAgo() {
    return DateTime.now().subtract(const Duration(days: 7));
  }
}