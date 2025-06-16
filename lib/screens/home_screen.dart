import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../models/metrics.dart';
import '../services/habit_service.dart';
import '../widgets/drawer.dart';
import '../widgets/habit_progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HabitService _habitService = HabitService();

  Widget _buildHabitCard(Habit habit) {
    final color = Color(int.parse(habit.colorHex.substring(1), radix: 16) + 0xFF000000);
    final now = DateTime.now();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<Metrics?>(
          stream: _habitService.getHabitMetrics(habit.id!),
          builder: (context, snapshot) {
            final metrics = snapshot.data;
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera del hábito
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${habit.goalFrequency}x ${habit.periodType}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progreso del hábito
                  HabitProgress(
                    habit: habit,
                    metrics: metrics,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seguimiento semanal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final date = now.subtract(Duration(days: now.weekday - 1 - index));
                      final isCompleted = metrics?.completedDays?.any((t) => 
                        t.toDate().year == date.year && 
                        t.toDate().month == date.month && 
                        t.toDate().day == date.day
                      ) ?? false;
                      
                      return InkWell(
                        onTap: () async {
                          if (date.isAfter(now)) return; // No permitir marcar días futuros
                          
                          try {
                            if (isCompleted) {
                              // Si ya está completado, lo marcamos como fallido (lo desmarcamos)
                              await _habitService.markDayAsFailed(habit.id!, date);
                            } else {
                              // Si no está completado, lo marcamos como completado
                              await _habitService.markDayAsCompleted(habit.id!, date);
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: isCompleted 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCompleted 
                                  ? Colors.green
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isCompleted ? '✅' : '⭕',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Días de la semana
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('L', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('M', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('X', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('J', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('V', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('S', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('D', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              // Marcar solo el día actual como completado
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              await _habitService.markDayAsCompleted(habit.id!, today);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Hábito completado! 🎉'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Completado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              // Marcar solo el día actual como fallido
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              await _habitService.markDayAsFailed(habit.id!, today);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No te preocupes, ¡mañana será mejor! 💪'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Fallido'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inicio',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFFDEA4CE),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF6FA),
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<List<Habit>>(
          stream: _habitService.getStartedHabits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final habits = snapshot.data ?? [];

            if (habits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 80,
                      color: const Color(0xFFDEA4CE).withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Comienza tu viaje!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D3F5B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes hábitos iniciados.\nVe a la sección de hábitos para comenzar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF6D3F5B).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/habits'),
                      icon: const Icon(Icons.add),
                      label: const Text('Ir a Hábitos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7E57C2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habits.length,
              itemBuilder: (context, index) => _buildHabitCard(habits[index]),
            );
          },
        ),
      ),
    );
  }
}