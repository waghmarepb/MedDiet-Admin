import 'package:flutter/material.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/services/analytics_service.dart';
import 'package:meddiet/widgets/common_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  AnalyticsData? _analyticsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AnalyticsService.fetchAnalytics();
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
        child: Column(
          children: [
            CommonHeader(
              title: 'Analytics Dashboard',
              action: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                label: const Text(
                  'Refresh Data',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Error: $_error',
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 4 Stat Cards with Vivid App Theme Colors
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Patients',
                  '${_analyticsData!.totalPatients}',
                  'Actual Count',
                  AppColors.primary,
                  Icons.people_alt_rounded,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'Meal Compliance',
                  '${_analyticsData!.mealCompliance.toStringAsFixed(0)}%',
                  'Last 30 Days',
                  AppColors.success,
                  Icons.restaurant_rounded,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'Exercise Compliance',
                  '${_analyticsData!.exerciseCompliance.toStringAsFixed(0)}%',
                  'Last 30 Days',
                  AppColors.accent,
                  Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'Avg. Compliance',
                  '${_analyticsData!.avgCompliance.toStringAsFixed(0)}%',
                  'Overall Score',
                  AppColors.info,
                  Icons.favorite_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Main Chart Card
          _buildMainChartCard(),
          const SizedBox(height: 40),

          // Breakdown Analysis
          const Text(
            'Breakdown Analysis',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBreakdownCard(
                  'Patient Progress',
                  'Distribution by goal category.',
                  _analyticsData!.planBreakdown,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildPieBreakdownCard(
                  'Gender Diversity',
                  'Patient demographic split.',
                  _analyticsData!.genderBreakdown,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDonutBreakdownCard(
                  'Age Groups',
                  'Patient age segmentation.',
                  _analyticsData!.ageBreakdown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color themeColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: themeColor, size: 24),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChartCard() {
    final now = DateTime.now();
    final dateRange =
        '${DateFormat('MMM d').format(DateTime(now.year, now.month, 1))} - ${DateFormat('MMM d').format(now)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Chart Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: AppColors.textGrey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Compliance Trend',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patient activity and plan adherence',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildTopStat(
                      'Avg Score',
                      '${_analyticsData!.avgCompliance.toStringAsFixed(1)}%',
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.primary.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    _buildTopStat('Target', '90.0%'),
                  ],
                ),
              ],
            ),
          ),

          // Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.divider.withValues(alpha: 0.2),
                      strokeWidth: 1,
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
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 != 0) return const SizedBox();
                          try {
                            final date = DateTime(
                              now.year,
                              now.month,
                              value.toInt(),
                            );
                            return Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 10,
                              ),
                            );
                          } catch (e) {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _analyticsData!.dailyData
                          .map((d) => FlSpot(d.date.day.toDouble(), d.value))
                          .toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chart Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateRange,
                      style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined, size: 14),
                  label: const Text(
                    'Export CSV',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textGrey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(
    String title,
    String subtitle,
    List<CategoryData> data,
    Color barColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.isEmpty
                    ? 10
                    : data.map((e) => e.value).reduce((a, b) => a > b ? a : b) *
                          1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= data.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            data[value.toInt()].label.substring(0, 3),
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: barColor,
                        width: 16,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieBreakdownCard(
    String title,
    String subtitle,
    List<CategoryData> data,
  ) {
    final List<Color> chartColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      AppColors.primaryLight,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final d = entry.value;
                  return PieChartSectionData(
                    color: chartColors[index % chartColors.length],
                    value: d.value,
                    title: '${d.value.toInt()}',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: chartColors[index % chartColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    d.label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutBreakdownCard(
    String title,
    String subtitle,
    List<CategoryData> data,
  ) {
    final List<Color> chartColors = [
      AppColors.sidebarBackground,
      AppColors.primary,
      AppColors.accent,
      AppColors.primaryLight,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 35,
                sections: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final d = entry.value;
                  return PieChartSectionData(
                    color: chartColors[index % chartColors.length],
                    value: d.value,
                    title: '', // Hide titles on donut for cleaner look
                    radius: 15,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: chartColors[index % chartColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    d.label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
