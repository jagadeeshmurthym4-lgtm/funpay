import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ─── TIME RANGE SELECTOR ────────────────────────────────────
enum TimeRange { daily, weekly, monthly }

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selected;
  final Function(TimeRange) onChanged;

  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TimeRange.values.map((range) {
          final isSelected = selected == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    range.name[0].toUpperCase() + range.name.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── EARNINGS BAR CHART ─────────────────────────────────────
class EarningsBarChart extends StatelessWidget {
  final List<double> earningsData;
  final List<String> labels;
  final Color barColor;
  final double maxVal;
  final String unit;

  EarningsBarChart({
    super.key,
    required this.earningsData,
    required this.labels,
    this.barColor = const Color(0xFF4ADE80),
    double? maxVal,
    this.unit = '₹',
  }) : maxVal = maxVal ?? (earningsData.isEmpty ? 1 : earningsData.reduce((a, b) => a > b ? a : b));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveMax = maxVal > 0 ? maxVal * 1.2 : 1.0;

    if (earningsData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('No earnings data yet',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: effectiveMax,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '$unit${rod.toY.toStringAsFixed(2)}',
                  TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '$unit${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: effectiveMax / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: earningsData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: barColor,
                  width: entry.value == maxVal && maxVal > 0 ? 18 : 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: effectiveMax,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      ),
    );
  }
}

// ─── EARNINGS PIE CHART ─────────────────────────────────────
class EarningsPieChart extends StatelessWidget {
  final Map<String, double> breakdown;
  final List<Color> colors;

  static const defaultColors = [
    Color(0xFF4ADE80),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  const EarningsPieChart({
    super.key,
    required this.breakdown,
    this.colors = defaultColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    final filtered = breakdown.entries.where((e) => e.value > 0).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 40,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('No earnings data',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {},
              ),
              sections: filtered.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final percentage = total > 0 ? (e.value / total * 100) : 0.0;
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: e.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  badgeWidget: null,
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: filtered.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final percentage = total > 0 ? (e.value / total * 100) : 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key} (${percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── EARNINGS TREND CARD ────────────────────────────────────
class EarningsTrendCard extends StatelessWidget {
  final double todayEarnings;
  final double yesterdayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double lifetimeEarnings;

  const EarningsTrendCard({
    super.key,
    required this.todayEarnings,
    required this.yesterdayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.lifetimeEarnings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendUp = todayEarnings >= yesterdayEarnings;
    final trendDiff = yesterdayEarnings > 0
        ? ((todayEarnings - yesterdayEarnings) / yesterdayEarnings * 100).abs()
        : 100.0;

    return Row(
      children: [
        _buildTrendItem(theme, 'Today', '₹${todayEarnings.toStringAsFixed(2)}',
            trendUp ? Icons.trending_up : Icons.trending_down,
            trendUp ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
            yesterdayEarnings > 0 ? '${trendDiff.toStringAsFixed(0)}%' : 'New'),
        const SizedBox(width: 12),
        _buildTrendItem(theme, 'This Week', '₹${weeklyEarnings.toStringAsFixed(2)}',
            Icons.calendar_view_week_outlined, const Color(0xFF3B82F6), null),
        const SizedBox(width: 12),
        _buildTrendItem(theme, 'This Month', '₹${monthlyEarnings.toStringAsFixed(2)}',
            Icons.calendar_month_outlined, const Color(0xFFA855F7), null),
        const SizedBox(width: 12),
        _buildTrendItem(theme, 'Lifetime', '₹${lifetimeEarnings.toStringAsFixed(2)}',
            Icons.all_inclusive_outlined, const Color(0xFFF59E0B), null),
      ],
    );
  }

  Widget _buildTrendItem(ThemeData theme, String label, String value,
      IconData icon, Color color, String? badge) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
            prefix: '₹',
            decimals: 2,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 8, color: theme.colorScheme.onSurfaceVariant)),
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
            ),
        ],
      ),
    );
  }
}
