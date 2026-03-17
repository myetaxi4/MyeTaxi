import 'package:cloud_firestore/cloud_firestore.dart';

class TripPoint {
  final double lat;
  final double lng;
  final double speed;
  final DateTime timestamp;

  TripPoint({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.timestamp,
  });

  factory TripPoint.fromMap(Map<String, dynamic> m) => TripPoint(
    lat: m['lat'].toDouble(),
    lng: m['lng'].toDouble(),
    speed: m['speed'].toDouble(),
    timestamp: (m['timestamp'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'lat': lat, 'lng': lng, 'speed': speed,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

class Trip {
  final String id;
  final String vehicleId;
  final String driverId;
  final String vehiclePlate;
  final String driverName;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final double maxSpeed;
  final double avgSpeed;
  final int harshBrakes;
  final int harshAccelerations;
  final double estimatedRevenue;
  final List<TripPoint> route;
  final bool isActive;

  Trip({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.vehiclePlate,
    required this.driverName,
    required this.startTime,
    this.endTime,
    this.distanceKm = 0,
    this.maxSpeed = 0,
    this.avgSpeed = 0,
    this.harshBrakes = 0,
    this.harshAccelerations = 0,
    this.estimatedRevenue = 0,
    this.route = const [],
    this.isActive = true,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      vehicleId: d['vehicleId'] ?? '',
      driverId: d['driverId'] ?? '',
      vehiclePlate: d['vehiclePlate'] ?? '',
      driverName: d['driverName'] ?? '',
      startTime: (d['startTime'] as Timestamp).toDate(),
      endTime: (d['endTime'] as Timestamp?)?.toDate(),
      distanceKm: (d['distanceKm'] ?? 0).toDouble(),
      maxSpeed: (d['maxSpeed'] ?? 0).toDouble(),
      avgSpeed: (d['avgSpeed'] ?? 0).toDouble(),
      harshBrakes: d['harshBrakes'] ?? 0,
      harshAccelerations: d['harshAccelerations'] ?? 0,
      estimatedRevenue: (d['estimatedRevenue'] ?? 0).toDouble(),
      route: (d['route'] as List<dynamic>? ?? [])
          .map((p) => TripPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      isActive: d['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vehicleId': vehicleId,
    'driverId': driverId,
    'vehiclePlate': vehiclePlate,
    'driverName': driverName,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    'distanceKm': distanceKm,
    'maxSpeed': maxSpeed,
    'avgSpeed': avgSpeed,
    'harshBrakes': harshBrakes,
    'harshAccelerations': harshAccelerations,
    'estimatedRevenue': estimatedRevenue,
    'route': route.map((p) => p.toMap()).toList(),
    'isActive': isActive,
  };

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  String get durationFormatted {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  // Revenue calc: AED 2.5 base + 1.8/km (Uber-style estimate)
  static double calculateRevenue(double km) => km > 0 ? 2.5 + (km * 1.8) : 0;
}
