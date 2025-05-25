import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PageDiagram extends StatelessWidget {
  PageDiagram({super.key});

  final List<String> groups = ['Team A', 'Team B', 'Team C', 'Team D'];
  final List<int> drinks = [12, 18, 7, 22];

  @override
  Widget build(BuildContext context) {
    final maxY = (drinks.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Getränke pro Gruppe',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < groups.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(groups[index]),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true),
                    barGroups: List.generate(groups.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: drinks[i].toDouble(),
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.deepPurpleAccent],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            width: 22,
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
      ),
    );
  }
}
