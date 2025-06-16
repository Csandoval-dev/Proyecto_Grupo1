import 'package:flutter/material.dart';

class WeekDaySelector extends StatelessWidget {
  final List<bool?> dayStates;
  final Function(int) onDayTap;

  const WeekDaySelector({
    Key? key,
    required this.dayStates,
    required this.onDayTap,
  }) : super(key: key);

  Widget _buildDayButton(int index, bool? isCompleted) {
    final color = isCompleted == null 
        ? Colors.grey
        : isCompleted 
            ? Colors.green 
            : Colors.red;

    return InkWell(
      onTap: () => onDayTap(index),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            isCompleted == null 
                ? '⭕'
                : isCompleted 
                    ? '✅' 
                    : '❌',
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            7,
            (index) => _buildDayButton(index, dayStates[index]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('L', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('M', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('M', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('J', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('V', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('S', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('D', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}