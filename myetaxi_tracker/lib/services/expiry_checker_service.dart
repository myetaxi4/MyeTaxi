import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/alert.dart';
import 'notification_service.dart';

class ExpiryCheckerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications = NotificationService();
  Timer? _dailyTimer;

  // Thresholds in days
  static const List<int> checkThresholds = [14, 30, 42, 60];

  void startDailyCheck(String ownerId) {
    // Run immediately on start
    checkAll(ownerId);

    // Run every 24 hours
    _dailyTimer = Timer.periodic(const Duration(hours: 24), (_) {
      checkAll(ownerId);
    });
  }

  Future<void> checkAll(String ownerId) async {
    await Future.wait([
      _checkVehicles(ownerId),
      _checkDrivers(ownerId),
    ]);
  }

  Future<void> _checkVehicles(String ownerId) async {
    final snap = await _db
        .collection('vehicles')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    for (final doc in snap.docs) {
      final v = Vehicle.fromFirestore(doc);

      // Registration
      await _checkExpiry(
        subject: '${v.plate} Registration',
        expiry: v.registrationExpiry,
        ownerId: ownerId,
        vehicleId: v.id,
      );

      // Insurance
      await _checkExpiry(
        subject: '${v.plate} Insurance',
        expiry: v.insuranceExpiry,
        ownerId: ownerId,
        vehicleId: v.id,
        alertType: AlertType.insuranceExpiry,
      );
    }
  }

  Future<void> _checkDrivers(String ownerId) async {
    final snap = await _db
        .collection('drivers')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    for (final doc in snap.docs) {
      final d = Driver.fromFirestore(doc);
      await _checkExpiry(
        subject: '${d.name}\'s Driving License',
        expiry: d.licenseExpiry,
        ownerId: ownerId,
        driverId: d.id,
        alertType: AlertType.licenseExpiry,
      );
    }
  }

  Future<void> _checkExpiry({
    required String subject,
    required DateTime expiry,
    required String ownerId,
    String? vehicleId,
    String? driverId,
    AlertType alertType = AlertType.registrationExpiry,
  }) async {
    final daysLeft = expiry.difference(DateTime.now()).inDays;

    if (!checkThresholds.contains(daysLeft) && daysLeft > 0) return;
    if (daysLeft < 0) {
      // Already expired
      await _createExpiryAlert(
        message: '$subject has EXPIRED! Immediate action required.',
        severity: AlertSeverity.critical,
        ownerId: ownerId,
        vehicleId: vehicleId,
        driverId: driverId,
        alertType: alertType,
        daysLeft: daysLeft,
      );
      return;
    }

    final severity = daysLeft <= 14
        ? AlertSeverity.critical
        : daysLeft <= 42
            ? AlertSeverity.warning
            : AlertSeverity.info;

    await _createExpiryAlert(
      message: '$subject expires in $daysLeft days. Please renew.',
      severity: severity,
      ownerId: ownerId,
      vehicleId: vehicleId,
      driverId: driverId,
      alertType: alertType,
      daysLeft: daysLeft,
    );
  }

  Future<void> _createExpiryAlert({
    required String message,
    required AlertSeverity severity,
    required String ownerId,
    required AlertType alertType,
    required int daysLeft,
    String? vehicleId,
    String? driverId,
  }) async {
    // Avoid duplicate alerts — check if one was created today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final existing = await _db
        .collection('alerts')
        .where('ownerId', isEqualTo: ownerId)
        .where('type', isEqualTo: alertType.name)
        .where('vehicleId', isEqualTo: vehicleId)
        .where('driverId', isEqualTo: driverId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // Already alerted today

    await _db.collection('alerts').add({
      'type': alertType.name,
      'severity': severity.name,
      'message': message,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'ownerId': ownerId,
    });

    await _notifications.showExpiryAlert(
      subject: message.split(' expires')[0].split(' has')[0],
      daysLeft: daysLeft,
    );
  }

  void dispose() {
    _dailyTimer?.cancel();
  }
}
