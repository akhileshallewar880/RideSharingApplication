import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/admin_models.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/theme/admin_theme.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Load last 30 days by default
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(Duration(days: 30));
    
    // Load stats after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  void _loadStats() {
    ref.read(dashboardStatsProvider.notifier).loadStats(
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.date_range, color: Colors.white),
            label: Text(
              _startDate != null && _endDate != null
                  ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}'
                  : 'Select Date Range',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: _selectDateRange,
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: statsState.isLoading && statsState.stats == null
          ? Center(child: CircularProgressIndicator())
          : statsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: AdminTheme.errorColor),
                      SizedBox(height: 16),
                      Text(
                        statsState.error!,
                        style: TextStyle(color: AdminTheme.errorColor),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : statsState.stats == null
                  ? Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Key Metrics Cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth > 1200 ? 4 : 2;
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.5,
                                children: [
                                  _buildMetricCard(
                                    'Total Drivers',
                                    statsState.stats!.totalDrivers.toString(),
                                    Icons.people,
                                    AdminTheme.primaryColor,
                                    subtitle:
                                        '${statsState.stats!.activeDrivers} active',
                                  ),
                                  _buildMetricCard(
                                    'Pending Verifications',
                                    statsState.stats!.pendingVerifications
                                        .toString(),
                                    Icons.pending_actions,
                                    AdminTheme.warningColor,
                                    subtitle: 'Awaiting review',
                                  ),
                                  _buildMetricCard(
                                    'Total Rides',
                                    statsState.stats!.totalRides.toString(),
                                    Icons.local_taxi,
                                    AdminTheme.infoColor,
                                    subtitle:
                                        '${statsState.stats!.completedRides} completed',
                                  ),
                                  _buildMetricCard(
                                    'Total Revenue',
                                    '₹${_formatNumber(statsState.stats!.totalRevenue)}',
                                    Icons.attach_money,
                                    AdminTheme.successColor,
                                    subtitle:
                                        '₹${_formatNumber(statsState.stats!.todayRevenue)} today',
                                  ),
                                  _buildMetricCard(
                                    'Active Rides',
                                    statsState.stats!.activeRides.toString(),
                                    Icons.navigation,
                                    AdminTheme.accentColor,
                                    subtitle: 'In progress',
                                  ),
                                  _buildMetricCard(
                                    'Total Passengers',
                                    statsState.stats!.totalPassengers.toString(),
                                    Icons.person_outline,
                                    AdminTheme.primaryLight,
                                    subtitle: 'Registered users',
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 32),

                          // Charts
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 1000) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildRevenueChart(
                                          statsState.stats!.dailyStats),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildRidesChart(
                                          statsState.stats!.dailyStats),
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildRevenueChart(
                                        statsState.stats!.dailyStats),
                                    SizedBox(height: 16),
                                    _buildRidesChart(
                                        statsState.stats!.dailyStats),
                                  ],
                                );
                              }
                            },
                          ),
                          SizedBox(height: 32),

                          // Driver Status Distribution
                          _buildDriverStatusCard(statsState.stats!),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: AdminTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<DailyStats> dailyStats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Revenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: dailyStats.isEmpty
                  ? Center(child: Text('No data available'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₹${_formatNumber(value)}',
                                  style: TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < dailyStats.length) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('dd/MM')
                                          .format(dailyStats[value.toInt()].date),
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dailyStats
                                .asMap()
                                .entries
                                .map((entry) => FlSpot(
                                      entry.key.toDouble(),
                                      entry.value.revenue,
                                    ))
                                .toList(),
                            isCurved: true,
                            color: AdminTheme.successColor,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AdminTheme.successColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesChart(List<DailyStats> dailyStats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: dailyStats.isEmpty
                  ? Center(child: Text('No data available'))
                  : BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < dailyStats.length) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('dd/MM')
                                          .format(dailyStats[value.toInt()].date),
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: dailyStats
                            .asMap()
                            .entries
                            .map((entry) => BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.rides.toDouble(),
                                      color: AdminTheme.infoColor,
                                      width: 16,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStatusCard(DashboardStats stats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatusBar(
                    'Active',
                    stats.activeDrivers,
                    stats.totalDrivers,
                    AdminTheme.successColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatusBar(
                    'Pending',
                    stats.pendingVerifications,
                    stats.totalDrivers,
                    AdminTheme.warningColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatusBar(
                    'Rejected',
                    stats.rejectedDrivers,
                    stats.totalDrivers,
                    AdminTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: AdminTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}
