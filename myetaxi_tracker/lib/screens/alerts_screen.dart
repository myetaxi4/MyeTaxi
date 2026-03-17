import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fleet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/alert.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final uid = ref.watch(currentUserIdProvider) ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            onPressed: () => FleetRepository.markAllAlertsRead(uid),
            child: const Text('Mark all read',
              style: TextStyle(color: AppTheme.accent, fontSize: 13)),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                    color: AppTheme.green, size: 64),
                  const SizedBox(height: 16),
                  Text('All clear!', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  const Text('No alerts at this time',
                    style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          // Group by severity
          final critical =
              alerts.where((a) => a.severity == AlertSeverity.critical).toList();
          final warning =
              alerts.where((a) => a.severity == AlertSeverity.warning).toList();
          final info =
              alerts.where((a) => a.severity == AlertSeverity.info).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Summary bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _SeverityStat(
                      count: critical.length,
                      label: 'Critical',
                      color: AppTheme.red,
                    ),
                    const SizedBox(width: 20),
                    _SeverityStat(
                      count: warning.length,
                      label: 'Warning',
                      color: AppTheme.orange,
                    ),
                    const SizedBox(width: 20),
                    _SeverityStat(
                      count: info.length,
                      label: 'Info',
                      color: AppTheme.yellow,
                    ),
                    const Spacer(),
                    Text('${alerts.where((a) => !a.isRead).length} unread',
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  ],
                ),
              ),

              if (critical.isNotEmpty) ...[
                const SectionHeader(title: '🚨 Critical'),
                ...critical.map((a) => _AlertCard(alert: a)),
              ],

              if (warning.isNotEmpty) ...[
                const SectionHeader(title: '⚠ Warnings'),
                ...warning.map((a) => _AlertCard(alert: a)),
              ],

              if (info.isNotEmpty) ...[
                const SectionHeader(title: 'ℹ Info'),
                ...info.map((a) => _AlertCard(alert: a)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SeverityStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SeverityStat({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$count',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AppAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.red),
      ),
      onDismissed: (_) => FleetRepository.deleteAlert(alert.id),
      child: GestureDetector(
        onTap: () {
          if (!alert.isRead) FleetRepository.markAlertRead(alert.id);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: alert.isRead
                ? AppTheme.card
                : alert.severityColor.withOpacity(0.06),
            border: Border(
              left: BorderSide(
                color: alert.severityColor,
                width: 3,
              ),
              top: BorderSide(color: AppTheme.border),
              right: BorderSide(color: AppTheme.border),
              bottom: BorderSide(color: AppTheme.border),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: alert.severityColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(alert.icon, color: alert.severityColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.typeLabel,
                      style: TextStyle(
                        color: alert.severityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(alert.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: alert.isRead
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('HH:mm · EEE d MMM').format(alert.timestamp),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
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
                    boxShadow: [
                      BoxShadow(
                        color: alert.severityColor.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
