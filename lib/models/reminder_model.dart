//lib/models/reminder_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final bool active;
  final TimeOfDay timeOfDay;
  final Map<String, bool> dayOfWeek;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Reminder({
    required this.id,
    required this.active,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String timeString = data['timeOfDay'] as String? ?? "00:00";
    final parts = timeString.split(":");
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return Reminder(
      id: doc.id,
      active: data['active'] as bool? ?? false,
      timeOfDay: TimeOfDay(hour: hour, minute: minute),
      dayOfWeek: Map<String, bool>.from(data['dayOfWeek'] as Map),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updateAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final hh = timeOfDay.hour.toString().padLeft(2, '0');
    final mm = timeOfDay.minute.toString().padLeft(2, '0');
    return {
      'active': active,
      'timeOfDay': '$hh:$mm',
      'dayOfWeek': dayOfWeek,
      'createdAt': createdAt,
      'updateAt': updatedAt,
    };
  }
}
