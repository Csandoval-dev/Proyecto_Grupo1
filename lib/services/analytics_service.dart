import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserContext(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('Usuarios')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return _getDefaultContext();
      }

      final userData = userDoc.data()!;
      final userName = userData['usuario'] ?? 
                      userData['email']?.split('@')[0] ?? 
                      'Usuario';

      // Obtener hábitos del usuario
      final habitsSnapshot = await _firestore
          .collection('Usuarios')
          .doc(userId)
          .collection('habits')
          .get();

      // Obtener métricas con ventana de tiempo ajustable
      final metricsSnapshot = await _getMetricsWithTimeWindow(userId);

      final analysisResult = await _analyzeUserData(
        habitsSnapshot.docs, 
        metricsSnapshot.docs,
        userId,
      );
      
      analysisResult['userName'] = userName;
      
      return analysisResult;
    } catch (e) {
      print('Error al obtener contexto del usuario: $e');
      return _getDefaultContext();
    }
  }

  Future<QuerySnapshot> _getMetricsWithTimeWindow(String userId) async {
    // Obtener métricas de las últimas 4 semanas para análisis de tendencias
    final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));
    
    return await _firestore
        .collection('Usuarios')
        .doc(userId)
        .collection('metrics')
        .where('startDate', isGreaterThan: fourWeeksAgo)
        .orderBy('startDate', descending: true)
        .get();
  }

  Future<Map<String, dynamic>> _analyzeUserData(
    List<QueryDocumentSnapshot> habits,
    List<QueryDocumentSnapshot> metrics,
    String userId,
  ) async {
    final activeHabits = habits.where((h) => h.data() != null).toList();
    final Map<String, List<double>> habitTrends = {};
    final Map<String, String> bestTimeForHabits = {};
    
    // Análisis de tendencias por hábito
    for (final habit in activeHabits) {
      final habitData = habit.data() as Map<String, dynamic>;
      final habitId = habit.id;
      final habitMetrics = metrics.where(
        (m) => (m.data() as Map<String, dynamic>)['habitId'] == habitId
      ).toList();
      
      habitTrends[habitId] = _calculateTrend(habitMetrics);
      bestTimeForHabits[habitId] = await _analyzeBestTime(userId, habitId);
    }

    // Calcular métricas generales
    final generalStats = _calculateGeneralStats(metrics, activeHabits);
    
    // Identificar patrones y sugerencias
    final patterns = _identifyPatterns(
      metrics, 
      habitTrends,
      bestTimeForHabits,
    );

    return {
      ...generalStats,
      'habitTrends': habitTrends,
      'bestTimes': bestTimeForHabits,
      'patterns': patterns,
      'lastAnalysis': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _calculateGeneralStats(
    List<QueryDocumentSnapshot> metrics,
    List<QueryDocumentSnapshot> habits,
  ) {
    double totalCompletion = 0;
    List<String> strugglingHabits = [];
    List<String> bestHabits = [];
    Map<String, double> weeklyProgress = {};

    for (final metric in metrics) {
      final data = metric.data() as Map<String, dynamic>;
      final done = data['countDone'] ?? 0;
      final missed = data['countMissed'] ?? 0;
      final total = done + missed;
      
      if (total > 0) {
        final completionRate = (done / total) * 100;
        totalCompletion += completionRate;

        final habitId = data['habitId'];
        final habit = habits.where((h) => h.id == habitId).firstOrNull;
        
        if (habit != null) {
          final habitData = habit.data() as Map<String, dynamic>;
          final name = habitData['name'] ?? 'Hábito';
          
          weeklyProgress[name] = completionRate;
          
          if (completionRate < 50) {
            strugglingHabits.add(name);
          } else if (completionRate > 80) {
            bestHabits.add(name);
          }
        }
      }
    }

    return {
      'totalHabits': habits.length,
      'weeklyCompletionRate': metrics.isNotEmpty ? totalCompletion / metrics.length : 0,
      'strugglingHabits': strugglingHabits,
      'bestHabits': bestHabits,
      'weeklyProgress': weeklyProgress,
    };
  }

  List<double> _calculateTrend(List<QueryDocumentSnapshot> habitMetrics) {
    // Calcular tendencia de las últimas 4 semanas
    List<double> weeklyRates = [];
    
    for (final metric in habitMetrics) {
      final data = metric.data() as Map<String, dynamic>;
      final done = data['countDone'] ?? 0;
      final missed = data['countMissed'] ?? 0;
      final total = done + missed;
      
      if (total > 0) {
        weeklyRates.add((done / total) * 100);
      }
    }
    
    return weeklyRates;
  }

  Future<String> _analyzeBestTime(String userId, String habitId) async {
    // Analizar los mejores momentos de cumplimiento
    final logs = await _firestore
        .collection('Usuarios')
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .where('status', isEqualTo: 'completed')
        .orderBy('logDate', descending: true)
        .limit(30)
        .get();

    if (logs.docs.isEmpty) return 'No hay suficientes datos';

    Map<String, int> timeDistribution = {};
    
    for (final log in logs.docs) {
      final data = log.data();
      final logDate = (data['logDate'] as Timestamp).toDate();
      final timeBlock = _getTimeBlock(logDate);
      
      timeDistribution[timeBlock] = (timeDistribution[timeBlock] ?? 0) + 1;
    }

    return timeDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _getTimeBlock(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 12) return 'mañana';
    if (hour >= 12 && hour < 18) return 'tarde';
    if (hour >= 18 && hour < 22) return 'noche';
    return 'noche tarde';
  }

  Map<String, dynamic> _identifyPatterns(
    List<QueryDocumentSnapshot> metrics,
    Map<String, List<double>> trends,
    Map<String, String> bestTimes,
  ) {
    final patterns = <String, dynamic>{};
    
    // Analizar tendencias generales
    for (final entry in trends.entries) {
      final trend = entry.value;
      if (trend.length >= 2) {
        final recentTrend = trend.take(2).toList();
        if (recentTrend[0] > recentTrend[1] + 10) {
          patterns['improving'] = true;
        } else if (recentTrend[0] < recentTrend[1] - 10) {
          patterns['declining'] = true;
        }
      }
    }

    // Identificar patrones de tiempo
    final timePatterns = bestTimes.values.toList();
    if (timePatterns.isNotEmpty) {
      final mostCommonTime = timePatterns
          .fold<Map<String, int>>({}, (map, time) {
            map[time] = (map[time] ?? 0) + 1;
            return map;
          })
          .entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      patterns['preferredTime'] = mostCommonTime;
    }

    return patterns;
  }

  Map<String, dynamic> _getDefaultContext() {
    return {
      'userName': 'Usuario',
      'totalHabits': 0,
      'weeklyCompletionRate': 0.0,
      'strugglingHabits': <String>[],
      'bestHabits': <String>[],
      'habitTrends': <String, List<double>>{},
      'bestTimes': <String, String>{},
      'patterns': <String, dynamic>{},
      'lastAnalysis': DateTime.now().toIso8601String(),
    };
  }
}