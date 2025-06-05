import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';  Codigo para conexion de Firebase Firestore
import 'package:fl_chart/fl_chart.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  /* Codigo para conexion de Firebase Firestore
  Future<Map<String, dynamic>> fetchMetricsData() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('users')
        .doc('ID_DEL_USUARIO')
        .collection('Metrics')
        .get();

    int countDone = 0;
    int totalExpected = 0;

    Map<String, int> perDay = {
      'Lun': 0,
      'Mar': 0,
      'Mié': 0,
      'Jue': 0,
      'Vie': 0,
      'Sáb': 0,
      'Dom': 0,
    };

    for (var doc in snapshot.docs) {
      var data = doc.data();
      countDone += (data['countDone'] ?? 0);
      int missed = (data['coutMissed'] ?? 0);
      int skipped = (data['countSkipped'] ?? 0);
      totalExpected += countDone + missed + skipped;

      DateTime start = (data['startDate'] as Timestamp).toDate();
      String day = ['Dom','Lun','Mar','Mié','Jue','Vie','Sáb'][start.weekday % 7];
      perDay[day] = (perDay[day]! + data['countDone']);
    }

    double porcentaje = totalExpected > 0
        ? (countDone / totalExpected) * 100
        : 0;

    return {
      'porcentaje': porcentaje,
      'habitosPorDia': perDay,
    };
  }*/

  Future<Map<String, dynamic>> fetchMockMetricsData() async {
    await Future.delayed(const Duration(seconds: 1)); // Simula carga

    int countDone = 40;
    int missed = 10;
    int skipped = 5;
    int totalExpected = countDone + missed + skipped;

    Map<String, int> perDay = {
      'Lun': 5,
      'Mar': 7,
      'Mié': 6,
      'Jue': 8,
      'Vie': 4,
      'Sáb': 6,
      'Dom': 4,
    };

    Map<String, int> categorias = {
      'Salud': 30,
      'Productividad': 25,
      'Trabajo': 30,
      'Hogar': 15,
    };

    return {
      'porcentaje': (countDone / totalExpected) * 100,
      'habitosPorDia': perDay,
      'categorias': categorias,
      'hoy': 4,
      'racha': 5,
      'ultimaActividad': '3 jun 2025',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métricas')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchMockMetricsData(),
        //future: fetchMetricsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No hay datos'));
          }

          final data = snapshot.data!;
          final porcentaje = data['porcentaje'] as double;
          final habitosPorDia = data['habitosPorDia'] as Map<String, int>;
          final categorias = data['categorias'] as Map<String, int>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricCard(
                      icon: Icons.check_circle_outline,
                      label: 'Hoy',
                      value: '${data['hoy']}',
                    ),
                    _MetricCard(
                      icon: Icons.whatshot,
                      label: 'Racha',
                      value: '${data['racha']} días',
                    ),
                    _MetricCard(
                      icon: Icons.calendar_today,
                      label: 'Última vez',
                      value: data['ultimaActividad'],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Progreso diario',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 40,
                                    sections: [
                                      PieChartSectionData(
                                        value: porcentaje,
                                        color: Colors.blueAccent,
                                        radius: 50,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: 100 - porcentaje,
                                        color: Colors.grey[300],
                                        radius: 50,
                                        showTitle: false,
                                      ),
                                    ],
                                  ),
                                ),
                                Text('${porcentaje.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Categoría',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 150,
                            child: PieChart(
                              PieChartData(
                                sections: categorias.entries.map((entry) {
                                  final index = categorias.keys.toList().indexOf(entry.key);
                                  final colors = [
                                    Colors.redAccent,
                                    Colors.orangeAccent,
                                    Colors.deepPurpleAccent,
                                    Colors.pinkAccent
                                  ];
                                  return PieChartSectionData(
                                    value: entry.value.toDouble(),
                                    title: '${entry.value}%',
                                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                                    color: colors[index % colors.length],
                                    radius: 45,
                                    showTitle: true,
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: categorias.keys.map((key) {
                              final index = categorias.keys.toList().indexOf(key);
                              final colors = [
                                Colors.redAccent,
                                Colors.orangeAccent,
                                Colors.deepPurpleAccent,
                                Colors.pinkAccent
                              ];
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: 10,
                                      height: 10,
                                      color: colors[index % colors.length]),
                                  const SizedBox(width: 4),
                                  Text(key, style: const TextStyle(fontSize: 12)),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text('Hábitos completados por día',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: BarChart(
                    BarChartData(
                      barGroups: habitosPorDia.entries.map((entry) {
                        return BarChartGroupData(
                          x: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                              .indexOf(entry.key),
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              width: 16,
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(days[value.toInt()], style: const TextStyle(fontSize: 12)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
