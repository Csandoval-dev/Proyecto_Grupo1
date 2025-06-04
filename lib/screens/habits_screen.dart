// lib/screens/habits_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../widgets/drawer.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  _HabitsScreenState createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final HabitService _habitService = HabitService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controladores para el formulario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _goalFrequencyController = TextEditingController();
  
  // Variables del formulario
  String _selectedCategory = 'Salud';
  String _selectedPeriodType = 'Diaria';
  String _selectedColor = '#7E57C2';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  
  // Variables de estado
  bool _isLoading = false;
  String _selectedFilter = 'Todos';
  
  // Opciones predefinidas
  final List<String> _categories = [
    'Salud', 'Ejercicio', 'Alimentación', 'Productividad', 'Lectura', 
    'Meditación', 'Trabajo', 'Hobbies', 'Finanzas', 'Familia', 'Otros'
  ];
  
  final List<String> _periodTypes = ['Diaria', 'Semanal', 'Mensual'];
  
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Púrpura', 'value': '#7E57C2'},
    {'name': 'Rosa', 'value': '#E91E63'},
    {'name': 'Azul', 'value': '#2196F3'},
    {'name': 'Verde', 'value': '#4CAF50'},
    {'name': 'Naranja', 'value': '#FF9800'},
    {'name': 'Rojo', 'value': '#F44336'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Índigo', 'value': '#3F51B5'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalFrequencyController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _goalFrequencyController.clear();
    _selectedCategory = 'Salud';
    _selectedPeriodType = 'Diaria';
    _selectedColor = '#7E57C2';
    _startDate = DateTime.now();
    _endDate = null;
  }

  void _fillFormForEdit(Habit habit) {
    _nameController.text = habit.name;
    _descriptionController.text = habit.description;
    _goalFrequencyController.text = habit.goalFrequency.toString();
    _selectedCategory = habit.category;
    _selectedPeriodType = habit.periodType;
    _selectedColor = habit.colorHex;
    _startDate = habit.startDate;
    _endDate = habit.endDate;
  }

  Future<void> _saveHabit({Habit? habitToEdit}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final habit = Habit(
        id: habitToEdit?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        colorHex: _selectedColor,
        goalFrequency: int.parse(_goalFrequencyController.text),
        periodType: _selectedPeriodType,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: habitToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      if (habitToEdit != null) {
        await _habitService.updateHabit(habitToEdit.id!, habit);
        _showSnackBar('✅ Hábito actualizado correctamente');
      } else {
        await _habitService.createHabit(habit);
        _showSnackBar('✅ Hábito creado correctamente');
      }

      _clearForm();
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('❌ Error al guardar hábito: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _habitService.deleteHabit(habit.id!);
        _showSnackBar('✅ Hábito eliminado correctamente');
      } catch (e) {
        _showSnackBar('❌ Error al eliminar hábito: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7E57C2),
      ),
    );
  }

  void _showHabitForm({Habit? habitToEdit}) {
    if (habitToEdit != null) {
      _fillFormForEdit(habitToEdit);
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFFF3E5F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _buildHabitForm(habitToEdit),
        ),
      ),
    );
  }

  Widget _buildHabitForm(Habit? habitToEdit) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  habitToEdit != null ? 'Editar Hábito' : 'Nuevo Hábito',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6D3F5B),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Nombre del hábito
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del hábito',
                prefixIcon: const Icon(Icons.check_circle_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre del hábito';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            
            // Frecuencia y período
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _goalFrequencyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Frecuencia',
                      prefixIcon: const Icon(Icons.repeat),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa la frecuencia';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Debe ser un número mayor a 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriodType,
                    decoration: InputDecoration(
                      labelText: 'Período',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _periodTypes.map((period) => DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedPeriodType = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Selector de color
            const Text(
              'Color del hábito:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6D3F5B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions.map((colorOption) {
                final isSelected = _selectedColor == colorOption['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorOption['value']),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(colorOption['value'].substring(1), radix: 16) + 0xFF000000),
                      shape: BoxShape.circle,
                      border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _saveHabit(habitToEdit: habitToEdit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7E57C2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          habitToEdit != null ? 'Actualizar Hábito' : 'Crear Hábito',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final color = Color(int.parse(habit.colorHex.substring(1), radix: 16) + 0xFF000000);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          title: Text(
            habit.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                habit.description,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    habit.category,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${habit.goalFrequency}x ${habit.periodType}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showHabitForm(habitToEdit: habit);
                  break;
                case 'delete':
                  _deleteHabit(habit);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF7E57C2)),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Hábitos',
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
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implementar filtros si es necesario
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
          stream: _habitService.getHabits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final habits = snapshot.data ?? [];

            if (habits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt,
                      size: 80,
                      color: const Color(0xFFDEA4CE).withOpacity(0.7),
                    ),
                    const SizedBox(height: 20),
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
                      'Aún no tienes hábitos creados.\nToca el botón + para crear tu primer hábito.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF6D3F5B).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return _buildHabitCard(habits[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitForm(),
        backgroundColor: const Color(0xFF7E57C2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}