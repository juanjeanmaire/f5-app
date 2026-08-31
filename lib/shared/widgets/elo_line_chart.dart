import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Gráfico de línea de la evolución de ELO. Con [compact] en true se
/// muestra sin ejes/grilla/interacción (para usar como preview chico
/// dentro de un ribbon); en false se muestra completo, con eje Y numerado
/// y tooltips al tocar.
class EloLineChart extends StatelessWidget {
  const EloLineChart({
    super.key,
    required this.values,
    this.compact = false,
    this.height = 160,
  });

  final List<double> values;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Todavía no hay suficientes partidos para graficar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final spots = [
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Margen para que la línea no quede pegada a los bordes del gráfico.
    final padding = ((maxValue - minValue) * 0.15).clamp(10, 100).toDouble();
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minValue - padding,
          maxY: maxValue + padding,
          gridData: FlGridData(show: !compact),
          titlesData: FlTitlesData(
            show: !compact,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !compact,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  value.round().toString(),
                  style: const TextStyle(fontSize: 10, color: AppColors.cream),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: !compact),
          lineTouchData: LineTouchData(enabled: !compact),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: accent,
              barWidth: compact ? 2 : 3,
              dotData: FlDotData(show: !compact),
              belowBarData: BarAreaData(
                show: true,
                color: accent.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
