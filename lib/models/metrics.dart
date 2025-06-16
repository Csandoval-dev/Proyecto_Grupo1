import 'package:cloud_firestore/cloud_firestore.dart';

class Metrics {
  final String habitId;
  final String period;
  final int countDone;
  final int countMissed;
  final int countSkipped;
  final DateTime startDate;
  final DateTime endDate;
  final List<Timestamp> completedDays; // Agregado

  Metrics({
    required this.habitId,
    required this.period,
    required this.countDone,
    required this.countMissed,
    required this.countSkipped,
    required this.startDate,
    required this.endDate,
    required this.completedDays, // Agregado
  });

  factory Metrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Metrics(
      habitId: data['habitId'] ?? '',
      period: data['period'] ?? '',
      countDone: data['countDone'] ?? 0,
      countMissed: data['countMissed'] ?? 0,
      countSkipped: data['countSkipped'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      completedDays: (data['completedDays'] as List<dynamic>?)
          ?.map((day) => day as Timestamp)
          .toList() ?? [], // Agregado
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habitId,
      'period': period,
      'countDone': countDone,
      'countMissed': countMissed,
      'countSkipped': countSkipped,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'completedDays': completedDays, // Agregado
    };
  }

  // Métodos de ayuda
  bool isDayCompleted(DateTime date) {
    return completedDays.any((timestamp) {
      final completedDate = timestamp.toDate();
      return completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day;
    });
  }

  // Copia con modificaciones
  Metrics copyWith({
    String? habitId,
    String? period,
    int? countDone,
    int? countMissed,
    int? countSkipped,
    DateTime? startDate,
    DateTime? endDate,
    List<Timestamp>? completedDays,
  }) {
    return Metrics(
      habitId: habitId ?? this.habitId,
      period: period ?? this.period,
      countDone: countDone ?? this.countDone,
      countMissed: countMissed ?? this.countMissed,
      countSkipped: countSkipped ?? this.countSkipped,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completedDays: completedDays ?? this.completedDays,
    );
  }
}