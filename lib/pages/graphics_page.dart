import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistics_service.dart';

class GraphicsPage extends StatefulWidget {
  const GraphicsPage({super.key});

  @override
  State<GraphicsPage> createState() => _GraphicsPageState();
}

class _GraphicsPageState extends State<GraphicsPage> {
  final StatisticsService _statsService = StatisticsService();
  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);

  bool _isLoading = true;
  Map<String, int> _monthlyData = {};
  Map<String, int> _statusData = {};
  Map<String, int> _weekdayData = {};
  int _uniquePatientsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return;

    setState(() => _isLoading = true);

    try {
      print('📊 Cargando estadísticas para doctor: $doctorId');

      final monthlyData = await _statsService.getAppointmentsByMonth(doctorId);
      print('📊 Datos mensuales: $monthlyData');

      final statusData = await _statsService.getAppointmentsByStatus(doctorId);
      print('📊 Datos de estado: $statusData');

      final weekdayData = await _statsService.getAppointmentsByWeekday(
        doctorId,
      );
      print('📊 Datos por día: $weekdayData');

      final patientsCount = await _statsService.getUniquePatientsCount(
        doctorId,
      );
      print('📊 Pacientes únicos: $patientsCount');

      setState(() {
        _monthlyData = monthlyData;
        _statusData = statusData;
        _weekdayData = weekdayData;
        _uniquePatientsCount = patientsCount;
        _isLoading = false;
      });

      print('✅ Estadísticas cargadas exitosamente');
    } catch (e, stackTrace) {
      print('❌ Error cargando estadísticas: $e');
      print('📚 StackTrace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de resumen
              _buildSummaryCard(),
              const SizedBox(height: 20),

              // Gráfica 1: Citas por mes (Línea)
              _buildChartCard(
                title: 'Citas por Mes',
                subtitle: 'Últimos 6 meses',
                icon: Icons.trending_up,
                child: _buildMonthlyLineChart(),
              ),
              const SizedBox(height: 20),

              // Gráfica 2: Estado de citas (Pie)
              _buildChartCard(
                title: 'Estado de las Citas',
                subtitle: 'Distribución general',
                icon: Icons.pie_chart,
                child: _buildStatusPieChart(),
              ),
              const SizedBox(height: 20),

              // Gráfica 3: Citas por día de la semana (Barras)
              _buildChartCard(
                title: 'Citas por Día de la Semana',
                subtitle: 'Distribución semanal',
                icon: Icons.bar_chart,
                child: _buildWeekdayBarChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAppointments = _statusData.values.fold(0, (a, b) => a + b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: primaryColor, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Resumen General',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Citas',
                  totalAppointments.toString(),
                  Icons.event,
                  primaryColor,
                ),
                _buildSummaryItem(
                  'Pacientes',
                  _uniquePatientsCount.toString(),
                  Icons.people,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Completadas',
                  _statusData['Completadas'].toString(),
                  Icons.check_circle,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(height: 250, child: child),
          ],
        ),
      ),
    );
  }

  // GRÁFICA 1: Línea - Citas por mes
  Widget _buildMonthlyLineChart() {
    if (_monthlyData.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final spots = _monthlyData.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    final maxY =
        _monthlyData.values.reduce((a, b) => a > b ? a : b).toDouble() + 2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < _monthlyData.length) {
                  final monthName = _monthlyData.keys
                      .elementAt(index)
                      .split(' ')[0];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      monthName,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: spots.length - 1.toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [primaryColor, accentColor]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: primaryColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.3),
                  accentColor.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final monthName = _monthlyData.keys.elementAt(
                  barSpot.x.toInt(),
                );
                return LineTooltipItem(
                  '$monthName\n${barSpot.y.toInt()} citas',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // GRÁFICA 2: Pie - Estado de citas
  Widget _buildStatusPieChart() {
    if (_statusData.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final total = _statusData.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No hay citas registradas'));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.blue,
                  value: _statusData['Agendadas']!.toDouble(),
                  title:
                      '${((_statusData['Agendadas']! / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: _statusData['Completadas']!.toDouble(),
                  title:
                      '${((_statusData['Completadas']! / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: _statusData['Canceladas']!.toDouble(),
                  title:
                      '${((_statusData['Canceladas']! / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                'Agendadas',
                _statusData['Agendadas']!,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                'Completadas',
                _statusData['Completadas']!,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                'Canceladas',
                _statusData['Canceladas']!,
                Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  // GRÁFICA 3: Barras - Citas por día de la semana
  Widget _buildWeekdayBarChart() {
    if (_weekdayData.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final maxY =
        _weekdayData.values.reduce((a, b) => a > b ? a : b).toDouble() + 2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = _weekdayData.keys.elementAt(group.x.toInt());
              return BarTooltipItem(
                '$day\n${rod.toY.toInt()} citas',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < _weekdayData.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      _weekdayData.keys.elementAt(index),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        barGroups: _weekdayData.entries.toList().asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value.toDouble(),
                gradient: LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
      ),
    );
  }
}
