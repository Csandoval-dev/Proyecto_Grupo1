import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/metrics.dart';

class HabitProgress extends StatelessWidget {
  final Habit habit;
  final Metrics? metrics;

  const HabitProgress({
    Key? key,
    required this.habit,
    required this.metrics,
  }) : super(key: key);

  double get completionRate {
    if (metrics == null) return 0;
    // Calculamos basado en días completados esta semana
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final completedThisWeek = metrics?.completedDays.where((t) {
      final date = t.toDate();
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             date.isBefore(startOfWeek.add(const Duration(days: 7)));
    }).length ?? 0;
    return (completedThisWeek / 7).clamp(0.0, 1.0);
  }

  String get progressText {
    // Contamos los días completados esta semana
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final completedThisWeek = metrics?.completedDays.where((t) {
      final date = t.toDate();
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             date.isBefore(startOfWeek.add(const Duration(days: 7)));
    }).length ?? 0;
    return '$completedThisWeek/7';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (completionRate * 100).round();
    final color = Color(int.parse(habit.colorHex.substring(1), radix: 16) + 0xFF000000);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: completionRate,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}