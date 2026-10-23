import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  List<dynamic> _conditions = [];
  List<dynamic> _ageStats = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final conditionsRes = await ApiService().getConditionStatistics();
      final ageRes = await ApiService().getAgeConditionStatistics();
      
      if (mounted) {
        setState(() {
          _conditions = conditionsRes;
          _ageStats = ageRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques IA')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tendances des maladies',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyse IA des pathologies les plus frequentes',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  _DiseaseChart(conditions: _conditions),
                  const SizedBox(height: 32),
                  Text(
                    'Maladies recurrentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _DiseaseList(conditions: _conditions),
                  const SizedBox(height: 32),
                  Text(
                    'Distribution par age',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _AgeDistributionChart(ageStats: _ageStats)),
                ],
              ),
            ),
    );
  }
}

class _DiseaseChart extends StatelessWidget {
  final List<dynamic> conditions;
  const _DiseaseChart({required this.conditions});
  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) return const Center(child: Text('Donnees insuffisantes'));

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Jun'];
                  if (value.toInt() < months.length) {
                    return Text(
                      months[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: conditions.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), double.parse(e.value['count'].toString()));
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiseaseList extends StatelessWidget {
  final List<dynamic> conditions;
  const _DiseaseList({required this.conditions});

  Color _getColor(int index) {
    const defaultColors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];
    return defaultColors[index % defaultColors.length];
  }
  final diseases = const [
    {
      'name': 'Grippe saisonniere',
      'count': 156,
      'trend': '+12%',
      'color': Colors.red,
    },
    {
      'name': 'Hypertension',
      'count': 134,
      'trend': '+5%',
      'color': Colors.orange,
    },
    {
      'name': 'Diabete Type 2',
      'count': 98,
      'trend': '+8%',
      'color': Colors.purple,
    },
    {'name': 'Allergies', 'count': 87, 'trend': '-3%', 'color': Colors.teal},
    {
      'name': 'Infections respiratoires',
      'count': 76,
      'trend': '+15%',
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: conditions.asMap().entries.map((entry) {
        final index = entry.key;
        final disease = entry.value;
        final color = _getColor(index);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease['condition'] as String? ?? 'Maladie',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${disease['count']} cas recenses',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Stable', style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AgeDistributionChart extends StatelessWidget {
  final List<dynamic> ageStats;
  const _AgeDistributionChart({required this.ageStats});
  @override
  Widget build(BuildContext context) {
    if (ageStats.isEmpty) return const Center(child: Text('Donnees insuffisantes'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < ageStats.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      ageStats[value.toInt()]['age_range'] ?? '?',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: ageStats.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: double.parse(entry.value['count'].toString()),
                color: Colors.blue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}


