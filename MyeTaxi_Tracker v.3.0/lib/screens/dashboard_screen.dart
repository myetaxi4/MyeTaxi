import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fleet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import 'tracking_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final vehicles = ref.watch(vehiclesProvider).value ?? [];
    final alerts = ref.watch(alertsProvider).value ?? [];
    final criticalAlerts = alerts.where((a) =>
        !a.isRead && a.severity == AlertSeverity.critical).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF0066FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_taxi, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('MyeTaxi Tracker'),
          ],
        ),
        actions: [
          Consumer(builder: (_, ref, __) {
            final count = ref.watch(unreadAlertCountProvider);
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {}, // handled by bottom nav
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppTheme.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$count',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.card,
        onRefresh: () async => ref.refresh(vehiclesProvider),
        child: ListView(
          children: [
            // Critical alerts banner
            if (criticalAlerts.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.1),
                  border: Border.all(color: AppTheme.red.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.crisis_alert, color: AppTheme.red, size: 18),
                        const SizedBox(width: 6),
                        Text('${criticalAlerts.length} CRITICAL ALERT${criticalAlerts.length > 1 ? 'S' : ''}',
                          style: const TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    ...criticalAlerts.take(3).map((a) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• ${a.message}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                    )),
                  ],
                ),
              ),

            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'TODAY — ${DateFormat('EEE, MMM d, yyyy').format(DateTime.now()).toUpperCase()}',
                style: AppTextStyles.label,
              ),
            ),

            // Stats row 1
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                StatCard(
                  icon: '💰',
                  label: 'Est. Revenue',
                  value: 'AED ${stats.todayRevenue.toStringAsFixed(0)}',
                  accentColor: AppTheme.green,
                ),
                const SizedBox(width: 10),
                StatCard(
                  icon: '📍',
                  label: 'Distance',
                  value: '${stats.todayDistance.toStringAsFixed(1)} km',
                  accentColor: AppTheme.accent,
                ),
              ]),
            ),
            const SizedBox(height: 10),

            // Stats row 2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                StatCard(
                  icon: '🚗',
                  label: 'Active Vehicles',
                  value: '${stats.movingVehicles}',
                  subLabel: 'of ${stats.totalVehicles} total',
                  accentColor: AppTheme.green,
                ),
                const SizedBox(width: 10),
                StatCard(
                  icon: '🗺️',
                  label: "Today's Trips",
                  value: '${stats.todayTrips}',
                  accentColor: AppTheme.accent,
                ),
              ]),
            ),

            const SectionHeader(title: 'Live Fleet Status'),

            ...vehicles.map((v) => _VehicleCard(vehicle: v)),

            if (vehicles.isEmpty)
              AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.directions_car_outlined, color: AppTheme.textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text('No vehicles registered yet',
                          style: AppTextStyles.label),
                      ],
                    ),
                  ),
                ),
              ),

            const SectionHeader(title: 'Recent Alerts'),

            ...alerts.take(4).map((a) => _AlertCard(alert: a)),

            if (alerts.isEmpty)
              AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.green, size: 36),
                        const SizedBox(height: 8),
                        Text('All clear — no alerts', style: AppTextStyles.label),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = vehicleStatusColor(vehicle.status);
    final speed = vehicle.speed;
    final limit = vehicle.speedLimit;

    return AppCard(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => TrackingScreen(vehicleId: vehicle.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveDot(
                color: vehicle.status == VehicleStatus.moving
                    ? AppTheme.green
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('${vehicle.plate} · GPS: ${vehicle.gpsSerial}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              SpeedGaugeWidget(speed: speed, limit: limit, size: 72),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(
                text: vehicle.status.name.toUpperCase(),
                color: statusColor,
              ),
              ExpiryChip(expiry: vehicle.registrationExpiry, label: 'Reg'),
              ExpiryChip(expiry: vehicle.insuranceExpiry, label: 'Ins'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.sensors, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('Last ping: just now · Limit: ${limit.toInt()} km/h',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AppAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: alert.severityColor.withOpacity(0.5),
      borderWidth: 1.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alert.icon, color: alert.severityColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.typeLabel,
                  style: TextStyle(
                    color: alert.severityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(alert.message,
                  style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm · d MMM').format(alert.timestamp),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!alert.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: alert.severityColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
