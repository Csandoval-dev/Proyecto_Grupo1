import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';
import '../models/metrics.dart';
import 'notification_service.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference? get _habitsCollection {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('Usuarios')
        .doc(_currentUserId)
        .collection('habits');
  }

  CollectionReference? get _metricsCollection {
    if (_currentUserId == null) return null;
    return _firestore
        .collection('Usuarios')
        .doc(_currentUserId)
        .collection('metrics');
  }

  Future<String?> createHabit(Habit habit) async {
    try {
      if (_habitsCollection == null) {
        throw Exception('Usuario no autenticado');
      }

      final docRef = await _habitsCollection!.add(habit.toFirestore());
      
      // Crear métricas iniciales
      await _metricsCollection?.doc(docRef.id).set({
        'habitId': docRef.id,
        'period': 'daily',
        'countDone': 0,
        'countMissed': 0,
        'countSkipped': 0,
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'completedDays': [],
      });
      
      await _notificationService.sendHabitCreatedNotification(habit.name);
      
      return docRef.id;
    } catch (e) {
      print('Error al crear hábito: $e');
      rethrow;
    }
  }

  Stream<Metrics?> getHabitMetrics(String habitId) {
    if (_metricsCollection == null) return Stream.value(null);

    return _metricsCollection!
        .doc(habitId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return Metrics.fromFirestore(doc);
        });
  }

  Future<void> markDayAsCompleted(String habitId, DateTime date) async {
    try {
      if (_metricsCollection == null) return;

      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateTimestamp = Timestamp.fromDate(normalizedDate);
      final docRef = _metricsCollection!.doc(habitId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'habitId': habitId,
          'period': 'daily',
          'countDone': 1,
          'countMissed': 0,
          'countSkipped': 0,
          'startDate': Timestamp.fromDate(DateTime.now()),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
          'completedDays': [dateTimestamp],
        });
      } else {
        final metrics = Metrics.fromFirestore(doc);
        final List<Timestamp> updatedDays = List.from(metrics.completedDays);
        
        if (!metrics.isDayCompleted(normalizedDate)) {
          updatedDays.add(dateTimestamp);
          await docRef.update({
            'completedDays': updatedDays,
            'countDone': metrics.countDone + 1,
          });
        }
      }
    } catch (e) {
      print('Error al marcar día como completado: $e');
      rethrow;
    }
  }

  Future<void> markDayAsFailed(String habitId, DateTime date) async {
    try {
      if (_metricsCollection == null) return;

      final normalizedDate = DateTime(date.year, date.month, date.day);
      final docRef = _metricsCollection!.doc(habitId);
      final doc = await docRef.get();

      if (doc.exists) {
        final metrics = Metrics.fromFirestore(doc);
        final List<Timestamp> updatedDays = metrics.completedDays
            .where((t) {
              final completedDate = t.toDate();
              return completedDate.year != normalizedDate.year ||
                     completedDate.month != normalizedDate.month ||
                     completedDate.day != normalizedDate.day;
            })
            .toList();

        await docRef.update({
          'completedDays': updatedDays,
          'countDone': metrics.countDone > 0 ? metrics.countDone - 1 : 0,
          'countMissed': metrics.countMissed + 1,
        });
      }
    } catch (e) {
      print('Error al marcar día como fallido: $e');
      rethrow;
    }
  }

  Future<void> startHabit(String habitId) async {
    try {
      if (_habitsCollection == null) {
        throw Exception('Usuario no autenticado');
      }

      final habitDoc = await _habitsCollection!.doc(habitId).get();
      if (!habitDoc.exists) {
        throw Exception('Hábito no encontrado');
      }

      final habit = Habit.fromFirestore(habitDoc);
      final updatedHabit = habit.copyWith(
        isStarted: true,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _habitsCollection!.doc(habitId).update(updatedHabit.toFirestore());
      await _notificationService.sendHabitStartedNotification(habit.name);
    } catch (e) {
      print('Error al iniciar hábito: $e');
      rethrow;
    }
  }

  Future<void> pauseHabit(String habitId) async {
    try {
      if (_habitsCollection == null) {
        throw Exception('Usuario no autenticado');
      }

      await _habitsCollection!.doc(habitId).update({
        'isStarted': false,
        'updatedAt': Timestamp.fromDate(DateTime.now())
      });
    } catch (e) {
      print('Error al pausar hábito: $e');
      rethrow;
    }
  }

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

  Stream<List<Habit>> getStartedHabits() {
    if (_habitsCollection == null) {
      return Stream.value([]);
    }

    return _habitsCollection!
        .where('isStarted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      var habits = snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
      habits.sort((a, b) => b.startedAt?.compareTo(a.startedAt ?? DateTime.now()) ?? 0);
      return habits;
    });
  }

  Stream<List<Habit>> getTodayHabits() {
    if (_habitsCollection == null) {
      return Stream.value([]);
    }

    return getStartedHabits().map((habits) {
      return habits.where((habit) => habit.appliesToday()).toList();
    });
  }

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

  Future<void> deleteHabit(String habitId) async {
    try {
      if (_habitsCollection == null) {
        throw Exception('Usuario no autenticado');
      }

      await _habitsCollection!.doc(habitId).delete();
      await _metricsCollection?.doc(habitId).delete();
    } catch (e) {
      print('Error al eliminar hábito: $e');
      rethrow;
    }
  }

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

  Future<List<String>> getCategories() async {
    try {
      if (_habitsCollection == null) return [];

      final snapshot = await _habitsCollection!.get();
      final categories = <String>{};
      
      for (var doc in snapshot.docs) {
        final habit = Habit.fromFirestore(doc);
        if (habit.category.isNotEmpty) {
          categories.add(habit.category);
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }
}