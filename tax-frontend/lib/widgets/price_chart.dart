import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceChart extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  final String currencyLabel;

  const PriceChart({super.key, required this.history, this.currencyLabel = 'USD'});

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int selectedIndex = 0;
  static const durations = [7, 30, 90];

  @override
  Widget build(BuildContext context) {
    final days = durations[selectedIndex];
    final data = widget.history;
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final value = (point['priceUsd'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }
    final minY = spots.isEmpty ? 0.0 : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.isEmpty ? 1.0 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var value in durations) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedIndex = durations.indexOf(value)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedIndex == durations.indexOf(value) ? const Color(0xFF0D1117) : const Color(0xFF101723),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${value}D',
                        style: TextStyle(
                          color: selectedIndex == durations.indexOf(value) ? const Color(0xFF00C896) : Colors.white60,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (value != durations.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Card(
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(enabled: true),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (val, meta) {
                      return Text(val.toStringAsFixed(0), style: const TextStyle(color: Colors.white38, fontSize: 10));
                    })),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: minY,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: const Color(0xFF00C896),
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF00C896).withOpacity(0.15)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Showing $days day history · ${widget.currencyLabel}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
