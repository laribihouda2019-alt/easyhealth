import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SymptomTrendChart extends StatelessWidget {
  final List<dynamic> trendData;
  final String symptom;

  const SymptomTrendChart({
    super.key,
    required this.trendData,
    required this.symptom,
  });

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return const Center(
        child: Text('Pas assez de données pour générer un graphique'),
      );
    }

    // Convert string months to indexed x values
    final List<FlSpot> spots = [];
    for (int i = 0; i < trendData.length; i++) {
      final double count = double.tryParse(trendData[i]['case_count'].toString()) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), count));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Évolution de: $symptom',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < trendData.length) {
                          String month = trendData[index]['month'].toString().split('-').last;
                          return Text(month, style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


