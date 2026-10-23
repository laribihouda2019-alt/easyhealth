import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class FrequentDiseasesScreen extends StatefulWidget {
  const FrequentDiseasesScreen({super.key});

  @override
  State<FrequentDiseasesScreen> createState() => _FrequentDiseasesScreenState();
}

class _FrequentDiseasesScreenState extends State<FrequentDiseasesScreen> {
  final _api = ApiService();
  bool _loading = false;
  Map<String, dynamic>? _data;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _data = null;
    });
    try {
      final result = await _api.aiFrequentDiseases(days: _days);
      if (mounted)
        setState(() {
          _data = result;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diseases = _data?['diseases'] as List? ?? [];
    final alerts = _data?['alerts'] as List? ?? [];

    // Find max value for chart scaling
    double maxY = 10;
    if (diseases.isNotEmpty) {
      final maxCount = diseases
          .map((e) => (e['count'] as num).toDouble())
          .reduce((a, b) => a > b ? a : b);
      if (maxCount > 8) maxY = maxCount + 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse Épidémique IA'),
        actions: [
          DropdownButton<int>(
            value: _days,
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            dropdownColor: theme.primaryColor,
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() => _days = newValue);
                _load();
              }
            },
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 Jours')),
              DropdownMenuItem(value: 30, child: Text('30 Jours')),
              DropdownMenuItem(value: 90, child: Text('90 Jours')),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _load(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text('Aucune donnée'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (alerts.isNotEmpty) ...[
                    Text(
                      'Alertes Épidémiques',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...alerts.map(
                      (a) => Card(
                        color: Colors.red.shade50,
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 32,
                          ),
                          title: Text(
                            a['message'] ?? 'Alerte',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            a['type'] ?? '',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Histogramme des Cas (Top 10)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (diseases.isEmpty)
                    const Center(
                      child: Text(
                        'Aucune donnée clinique disponible pour cette période.',
                      ),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < diseases.length) {
                                    final condition =
                                        diseases[index]['condition'].toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        condition.length > 8
                                            ? '${condition.substring(0, 8)}...'
                                            : condition,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: List.generate(diseases.length, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: (diseases[index]['count'] as num)
                                      .toDouble(),
                                  color: Colors.purple,
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}


