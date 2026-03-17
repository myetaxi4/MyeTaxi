import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AlertType {
  overspeed,
  harshBrake,
  harshAcceleration,
  registrationExpiry,
  insuranceExpiry,
  licenseExpiry,
  geofence,
  offline,
  lowBattery,
}

enum AlertSeverity { info, warning, critical }

class AppAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final String? vehicleId;
  final String? driverId;
  final DateTime timestamp;
  bool isRead;
  final String ownerId;

  AppAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.vehicleId,
    this.driverId,
    required this.timestamp,
    this.isRead = false,
    required this.ownerId,
  });

  factory AppAlert.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppAlert(
      id: doc.id,
      type: AlertType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => AlertType.overspeed,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == d['severity'],
        orElse: () => AlertSeverity.warning,
      ),
      message: d['message'] ?? '',
      vehicleId: d['vehicleId'],
      driverId: d['driverId'],
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      isRead: d['isRead'] ?? false,
      ownerId: d['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type': type.name,
    'severity': severity.name,
    'message': message,
    'vehicleId': vehicleId,
    'driverId': driverId,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
    'ownerId': ownerId,
  };

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.critical: return AppTheme.red;
      case AlertSeverity.warning: return AppTheme.orange;
      case AlertSeverity.info: return AppTheme.yellow;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.overspeed: return Icons.speed;
      case AlertType.harshBrake: return Icons.warning_rounded;
      case AlertType.harshAcceleration: return Icons.electric_bolt;
      case AlertType.registrationExpiry:
      case AlertType.insuranceExpiry:
      case AlertType.licenseExpiry: return Icons.assignment_late;
      case AlertType.geofence: return Icons.location_off;
      case AlertType.offline: return Icons.signal_wifi_off;
      case AlertType.lowBattery: return Icons.battery_alert;
    }
  }

  String get typeLabel {
    switch (type) {
      case AlertType.overspeed: return 'OVERSPEED';
      case AlertType.harshBrake: return 'HARSH BRAKE';
      case AlertType.harshAcceleration: return 'HARSH ACCELERATION';
      case AlertType.registrationExpiry: return 'REGISTRATION EXPIRY';
      case AlertType.insuranceExpiry: return 'INSURANCE EXPIRY';
      case AlertType.licenseExpiry: return 'LICENSE EXPIRY';
      case AlertType.geofence: return 'GEOFENCE BREACH';
      case AlertType.offline: return 'VEHICLE OFFLINE';
      case AlertType.lowBattery: return 'LOW BATTERY';
    }
  }
}
