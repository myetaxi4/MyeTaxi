import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/fleet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/trip.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(todayTripsProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Trips & Revenue')),
      body: tripsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trips) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Revenue summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.card,
                      AppTheme.green.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("TODAY'S REVENUE", style: AppTextStyles.label),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.green.withOpacity(0.4)),
                          ),
                          child: Text(
                            'EST. RATE AED 1.8/km',
                            style: TextStyle(
                                color: AppTheme.green.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AED ${stats.todayRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.route,
                          label: 'Distance',
                          value:
                              '${stats.todayDistance.toStringAsFixed(1)} km',
                          color: AppTheme.accent,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.map_outlined,
                          label: 'Trips',
                          value: '${trips.length}',
                          color: AppTheme.accent,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.access_time,
                          label: 'Active',
                          value: '${trips.where((t) => t.isActive).length}',
                          color: AppTheme.green,
                        ),
                      ),
                    ]),
                    if (trips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 8),
                      // Mini bar chart
                      SizedBox(
                        height: 80,
                        child: _RevenueBarChart(trips: trips),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border,
                            style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              size: 14, color: AppTheme.textMuted),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Revenue estimated at AED 2.50 base + 1.80/km. '
                              'Connect Uber / Careem API in Settings to sync actual fares.',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (trips.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.route, color: AppTheme.textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text('No trips today', style: AppTextStyles.label),
                      ],
                    ),
                  ),
                ),

              if (trips.isNotEmpty) ...[
                const SectionHeader(title: "Today's Trips"),
                ...trips.map((t) => _TripCard(trip: t)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final List<Trip> trips;
  const _RevenueBarChart({required this.trips});

  @override
  Widget build(BuildContext context) {
    final data = trips.take(8).toList().reversed.toList();
    return BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final t = e.value;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: t.estimatedRevenue,
                color: t.isActive ? AppTheme.green : AppTheme.accent,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scoreColor = trip.harshBrakes == 0 && trip.harshAccelerations == 0
        ? AppTheme.green
        : trip.harshBrakes <= 1
            ? AppTheme.orange
            : AppTheme.red;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: trip.isActive
                      ? AppTheme.green.withOpacity(0.1)
                      : AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: trip.isActive
                        ? AppTheme.green.withOpacity(0.3)
                        : AppTheme.accent.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  trip.isActive ? Icons.directions_car : Icons.check_circle_outline,
                  color: trip.isActive ? AppTheme.green : AppTheme.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.driverName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      '${trip.vehiclePlate} · '
                      '${DateFormat('HH:mm').format(trip.startTime)}'
                      '${trip.endTime != null ? ' → ${DateFormat('HH:mm').format(trip.endTime!)}' : ' (active)'}'
                      ' · ${trip.durationFormatted}',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AED ${trip.estimatedRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text('${trip.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(
                  text: 'Avg ${trip.avgSpeed.toInt()} km/h',
                  color: AppTheme.accent),
              StatusBadge(
                  text: 'Max ${trip.maxSpeed.toInt()} km/h',
                  color: trip.maxSpeed > 120 ? AppTheme.red : AppTheme.textMuted),
              if (trip.harshBrakes > 0)
                StatusBadge(
                    text: '${trip.harshBrakes} harsh brake',
                    color: scoreColor),
              if (trip.harshAccelerations > 0)
                StatusBadge(
                    text: '${trip.harshAccelerations} harsh accel',
                    color: AppTheme.orange),
              if (trip.isActive)
                StatusBadge(text: 'IN PROGRESS', color: AppTheme.green),
            ],
          ),
        ],
      ),
    );
  }
}
