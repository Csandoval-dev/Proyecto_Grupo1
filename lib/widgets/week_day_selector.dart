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
        ? const Color(0xFF9E9E9E)
        : isCompleted
            ? const Color(0xFF4CAF50)
            : const Color(0xFFE57373);

    return InkWell(
      onTap: () => onDayTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCompleted == null
                ? [
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.05),
                  ]
                : [
                    color,
                    color.withOpacity(0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: -3,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isCompleted == null
                  ? Icons.radio_button_unchecked_rounded
                  : isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
              key: ValueKey(isCompleted),
              color: isCompleted == null
                  ? Colors.grey.withOpacity(0.5)
                  : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('L', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
              Text('M', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
              Text('M', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
              Text('J', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
              Text('V', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
              Text('S', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
              Text('D', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              7,
              (index) => _buildDayButton(index, dayStates[index]),
            ),
          ),
        ],
      ),
    );
  }
}