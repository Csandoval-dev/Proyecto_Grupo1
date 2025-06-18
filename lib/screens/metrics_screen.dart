import 'package:corelife/widgets/drawer.dart';
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
      'hoy': 2,
      'racha': 4,
      'ultimaActividad': '18 jun 2025',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F7), // Fondo suave rosa claro
      appBar: AppBar(
        title: const Text(
          'Métricas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFDEA4CE), // Rosa principal
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDEA4CE), // Rosa principal
              ],
            ),
          ),
        ),
      ),
      drawer: const MenuDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F4F7), // Rosa muy claro
              Color(0xFFFCE4EC), // Rosa pastel
            ],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchMockMetricsData(),
          //future: fetchMetricsData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  'No hay datos',
                  style: TextStyle(
                    color: Color(0xFF424242),
                    fontSize: 16,
                  ),
                ),
              );
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
                  // Tarjetas de métricas principales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricCard(
                        icon: Icons.check_circle_outline,
                        label: 'Hoy',
                        value: '${data['hoy']}',
                        color: const Color(0xFFE91E63),
                        bgColor: Colors.white,
                      ),
                      _MetricCard(
                        icon: Icons.whatshot,
                        label: 'Racha',
                        value: '${data['racha']} días',
                        color: const Color(0xFFFF5722),
                        bgColor: Colors.white,
                      ),
                      _MetricCard(
                        icon: Icons.calendar_today,
                        label: 'Última vez',
                        value: data['ultimaActividad'],
                        color: const Color(0xFF9C27B0),
                        bgColor: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Sección de gráficos
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progreso diario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Progreso diario',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF424242),
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                            color: const Color(0xFFE91E63),
                                            radius: 50,
                                            showTitle: false,
                                          ),
                                          PieChartSectionData(
                                            value: 100 - porcentaje,
                                            color: const Color(0xFFF3E5F5),
                                            radius: 50,
                                            showTitle: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${porcentaje.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE91E63),
                                          ),
                                        ),
                                        const Text(
                                          'Completado',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF757575),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Categorías
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Por categoría',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF424242),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 150,
                                child: PieChart(
                                  PieChartData(
                                    sections: categorias.entries.map((entry) {
                                      final index = categorias.keys.toList().indexOf(entry.key);
                                      final colors = [
                                        const Color(0xFFE91E63), // Rosa principal
                                        const Color(0xFF9C27B0), // Púrpura
                                        const Color(0xFF673AB7), // Púrpura profundo
                                        const Color(0xFF3F51B5), // Índigo
                                      ];
                                      return PieChartSectionData(
                                        value: entry.value.toDouble(),
                                        title: '${entry.value}%',
                                        titleStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
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
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: categorias.keys.map((key) {
                                  final index = categorias.keys.toList().indexOf(key);
                                  final colors = [
                                    const Color(0xFFE91E63),
                                    const Color(0xFF9C27B0),
                                    const Color(0xFF673AB7),
                                    const Color(0xFF3F51B5),
                                  ];
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: colors[index % colors.length],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        key,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF424242),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Gráfico de barras
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hábitos completados por día',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                      width: 20,
                                      gradient: const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Color(0xFFE91E63),
                                          Color(0xFFAD1457),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
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
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          days[value.toInt()],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF757575),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF757575),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: const Color(0xFFF5F5F5),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}