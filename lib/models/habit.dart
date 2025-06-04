// lib/models/habit.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String? id;
  final String name;
  final String description;
  final String category;
  final String colorHex;
  final int goalFrequency;
  final String periodType;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.colorHex,
    required this.goalFrequency,
    required this.periodType,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor para crear desde Firestore
  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      colorHex: data['colorHex'] ?? '#7E57C2',
      goalFrequency: data['goalFrequency'] ?? 1,
      periodType: data['periodType'] ?? 'Diaria',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'colorHex': colorHex,
      'goalFrequency': goalFrequency,
      'periodType': periodType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // copyWith para actualizaciones
  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? colorHex,
    int? goalFrequency,
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      colorHex: colorHex ?? this.colorHex,
      goalFrequency: goalFrequency ?? this.goalFrequency,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}