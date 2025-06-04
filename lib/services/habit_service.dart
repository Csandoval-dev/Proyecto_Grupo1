// lib/services/habit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el UID del usuario actual
  String? get _currentUserId => _auth.currentUser?.uid;

  // Referencia a la colección de hábitos del usuario
  CollectionReference? get _habitsCollection {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('usuarios')
        .doc(_currentUserId)
        .collection('habits');
  }

  // Crear un nuevo hábito
  Future<String?> createHabit(Habit habit) async {
    try {
      if (_habitsCollection == null) {
        throw Exception('Usuario no autenticado');
      }

      final docRef = await _habitsCollection!.add(habit.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error al crear hábito: $e');
      rethrow;
    }
  }

  // Obtener todos los hábitos del usuario
  Stream<List<Habit>> getHabits() {
    if (_habitsCollection == null) {
      return Stream.value([]);
    }

    return _habitsCollection!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
    });
  }

  // Obtener un hábito específico
  Future<Habit?> getHabitById(String habitId) async {
    try {
      if (_habitsCollection == null) return null;

      final doc = await _habitsCollection!.doc(habitId).get();
      if (doc.exists) {
        return Habit.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener hábito: $e');
      return null;
    }
  }

  // Actualizar un hábito
  Future<void> updateHabit(String habitId, Habit habit) async {
    try {
      if (_habitsCollection == null) {
        throw Exception('Usuario no autenticado');
      }

      final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
      await _habitsCollection!.doc(habitId).update(updatedHabit.toFirestore());
    } catch (e) {
      print('Error al actualizar hábito: $e');
      rethrow;
    }
  }

  // Eliminar un hábito
  Future<void> deleteHabit(String habitId) async {
    try {
      if (_habitsCollection == null) {
        throw Exception('Usuario no autenticado');
      }

      await _habitsCollection!.doc(habitId).delete();
    } catch (e) {
      print('Error al eliminar hábito: $e');
      rethrow;
    }
  }

  // Obtener hábitos por categoría
  Stream<List<Habit>> getHabitsByCategory(String category) {
    if (_habitsCollection == null) {
      return Stream.value([]);
    }

    return _habitsCollection!
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
    });
  }

  // Obtener categorías únicas
  Future<List<String>> getCategories() async {
    try {
      if (_habitsCollection == null) return [];

      final snapshot = await _habitsCollection!.get();
      final categories = <String>{};
      
      for (var doc in snapshot.docs) {
        final habit = Habit.fromFirestore(doc);
        categories.add(habit.category);
      }
      
      return categories.toList()..sort();
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }
}