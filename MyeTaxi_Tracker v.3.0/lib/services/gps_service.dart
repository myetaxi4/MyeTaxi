import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/vehicle.dart';
import '../models/trip.dart';
import '../models/alert.dart';
import 'notification_service.dart';

/// GPS Data Packet — normalized from either SMS or Internet source
class GpsPacket {
  final String gpsSerial;
  final double lat;
  final double lng;
  final double speed;       // km/h
  final double? heading;    // degrees
  final double? altitude;
  final DateTime timestamp;
  final bool harshBrake;
  final bool harshAcceleration;
  final String source;      // 'sms' | 'internet'

  GpsPacket({
    required this.gpsSerial,
    required this.lat,
    required this.lng,
    required this.speed,
    this.heading,
    this.altitude,
    required this.timestamp,
    this.harshBrake = false,
    this.harshAcceleration = false,
    required this.source,
  });

  /// Parse common GPS SMS format:
  /// "GPSSERIAL,LAT,LNG,SPEED,HEADING,TIMESTAMP,FLAGS"
  /// Example: "GPS-TK-001,25.2048,55.2708,87.5,180,2026-03-14T10:22:00,HB=0,HA=0"
  static GpsPacket? fromSms(String smsBody) {
    try {
      final parts = smsBody.trim().split(',');
      if (parts.length < 6) return null;
      return GpsPacket(
        gpsSerial: parts[0].trim(),
        lat: double.parse(parts[1]),
        lng: double.parse(parts[2]),
        speed: double.parse(parts[3]),
        heading: parts.length > 4 ? double.tryParse(parts[4]) : null,
        timestamp: DateTime.tryParse(parts[5]) ?? DateTime.now(),
        harshBrake: smsBody.contains('HB=1'),
        harshAcceleration: smsBody.contains('HA=1'),
        source: 'sms',
      );
    } catch (e) {
      debugPrint('GPS SMS parse error: $e');
      return null;
    }
  }

  /// Parse JSON from Internet/WebSocket source
  /// { "serial": "GPS-TK-001", "lat": 25.2, "lng": 55.27, "speed": 87,
  ///   "heading": 180, "ts": "2026-03-14T10:22:00Z", "hb": false, "ha": false }
  static GpsPacket? fromJson(Map<String, dynamic> json) {
    try {
      return GpsPacket(
        gpsSerial: json['serial'] ?? json['gpsSerial'] ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
        heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
        altitude: json['alt'] != null ? (json['alt'] as num).toDouble() : null,
        timestamp: DateTime.tryParse(json['ts'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
        harshBrake: json['hb'] == true || json['harshBrake'] == true,
        harshAcceleration: json['ha'] == true || json['harshAcceleration'] == true,
        source: 'internet',
      );
    } catch (e) {
      debugPrint('GPS JSON parse error: $e');
      return null;
    }
  }
}

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications = NotificationService();

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _pollingTimer;
  String? _ownerId;

  // Cache: gpsSerial -> vehicleId
  final Map<String, String> _serialToVehicleId = {};
  final Map<String, String> _serialToVehiclePlate = {};
  final Map<String, double> _lastSpeed = {};
  final Map<String, double> _speedLimit = {};
  final Map<String, String> _activeTrip = {}; // vehicleId -> tripId

  final StreamController<GpsPacket> _packetStream =
      StreamController<GpsPacket>.broadcast();
  Stream<GpsPacket> get packetStream => _packetStream.stream;

  /// Initialize with owner ID and load vehicle registry
  Future<void> initialize(String ownerId) async {
    _ownerId = ownerId;
    await _loadVehicleRegistry();
    _listenFirestoreVehicles();
  }

  Future<void> _loadVehicleRegistry() async {
    final snap = await _db
        .collection('vehicles')
        .where('ownerId', isEqualTo: _ownerId)
        .get();
    for (final doc in snap.docs) {
      final v = Vehicle.fromFirestore(doc);
      _serialToVehicleId[v.gpsSerial] = v.id;
      _serialToVehiclePlate[v.gpsSerial] = v.plate;
      _speedLimit[v.gpsSerial] = v.speedLimit;
    }
  }

  void _listenFirestoreVehicles() {
    _db
        .collection('vehicles')
        .where('ownerId', isEqualTo: _ownerId)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final v = Vehicle.fromFirestore(doc);
        _serialToVehicleId[v.gpsSerial] = v.id;
        _serialToVehiclePlate[v.gpsSerial] = v.plate;
        _speedLimit[v.gpsSerial] = v.speedLimit;
      }
    });
  }

  // ─── SMS INGESTION ──────────────────────────────────────────────────────────
  /// Called by SMS listener (telephony package) when a GPS SMS arrives
  void ingestSms(String sender, String body) {
    final packet = GpsPacket.fromSms(body);
    if (packet != null) {
      debugPrint('[GPS-SMS] Received from $sender: ${packet.gpsSerial} @ ${packet.speed}km/h');
      _processPacket(packet);
    }
  }

  // ─── INTERNET / WEBSOCKET ───────────────────────────────────────────────────
  /// Connect to a WebSocket server broadcasting GPS data
  void connectWebSocket(String wsUrl) {
    _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _wsSubscription = _wsChannel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          // Handle array of packets or single packet
          if (json.containsKey('packets')) {
            for (final p in json['packets'] as List) {
              final packet = GpsPacket.fromJson(p as Map<String, dynamic>);
              if (packet != null) _processPacket(packet);
            }
          } else {
            final packet = GpsPacket.fromJson(json);
            if (packet != null) _processPacket(packet);
          }
        } catch (e) {
          debugPrint('[GPS-WS] Parse error: $e');
        }
      },
      onError: (e) => debugPrint('[GPS-WS] Error: $e'),
      onDone: () {
        debugPrint('[GPS-WS] Connection closed — reconnecting in 5s');
        Future.delayed(const Duration(seconds: 5), () {
          connectWebSocket(wsUrl);
        });
      },
    );
  }

  /// Poll an HTTP endpoint for GPS data (fallback if no WebSocket)
  void startHttpPolling(String baseUrl, {Duration interval = const Duration(seconds: 10)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      try {
        final resp = await http.get(Uri.parse('$baseUrl/gps/latest'));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data is List) {
            for (final p in data) {
              final packet = GpsPacket.fromJson(p as Map<String, dynamic>);
              if (packet != null) _processPacket(packet);
            }
          }
        }
      } catch (e) {
        debugPrint('[GPS-HTTP] Poll error: $e');
      }
    });
  }

  // ─── CORE PACKET PROCESSING ─────────────────────────────────────────────────
  Future<void> _processPacket(GpsPacket packet) async {
    _packetStream.add(packet);

    final vehicleId = _serialToVehicleId[packet.gpsSerial];
    if (vehicleId == null) {
      debugPrint('[GPS] Unknown serial: ${packet.gpsSerial}');
      return;
    }

    final isMoving = packet.speed > 2.0;
    final status = isMoving ? VehicleStatus.moving : VehicleStatus.idle;

    // Update vehicle doc in Firestore
    await _db.collection('vehicles').doc(vehicleId).update({
      'lat': packet.lat,
      'lng': packet.lng,
      'speed': packet.speed,
      'heading': packet.heading,
      'status': status.name,
      'lastUpdate': Timestamp.fromDate(packet.timestamp),
      'lastSource': packet.source,
    });

    // Manage active trip
    await _manageTripTracking(packet, vehicleId, isMoving);

    // Check for alerts
    await _checkAlerts(packet, vehicleId);

    _lastSpeed[packet.gpsSerial] = packet.speed;
  }

  Future<void> _manageTripTracking(
      GpsPacket packet, String vehicleId, bool isMoving) async {
    final currentTripId = _activeTrip[vehicleId];

    if (isMoving && currentTripId == null) {
      // Start new trip
      final tripRef = await _db.collection('trips').add({
        'vehicleId': vehicleId,
        'vehiclePlate': _serialToVehiclePlate[packet.gpsSerial] ?? '',
        'driverId': '',
        'driverName': '',
        'startTime': Timestamp.fromDate(packet.timestamp),
        'endTime': null,
        'distanceKm': 0,
        'maxSpeed': packet.speed,
        'avgSpeed': packet.speed,
        'harshBrakes': 0,
        'harshAccelerations': 0,
        'estimatedRevenue': 0,
        'route': [{'lat': packet.lat, 'lng': packet.lng, 'speed': packet.speed, 'timestamp': Timestamp.fromDate(packet.timestamp)}],
        'isActive': true,
        'ownerId': _ownerId,
      });
      _activeTrip[vehicleId] = tripRef.id;
    } else if (isMoving && currentTripId != null) {
      // Update ongoing trip
      final tripDoc = await _db.collection('trips').doc(currentTripId).get();
      if (!tripDoc.exists) return;
      final tripData = tripDoc.data() as Map<String, dynamic>;
      final route = List<Map<String, dynamic>>.from(tripData['route'] as List);
      double distKm = (tripData['distanceKm'] as num).toDouble();
      double maxSpeed = (tripData['maxSpeed'] as num).toDouble();

      // Calculate distance increment from last point
      if (route.isNotEmpty) {
        final last = route.last;
        final d = _haversine(last['lat'], last['lng'], packet.lat, packet.lng);
        distKm += d;
      }

      route.add({'lat': packet.lat, 'lng': packet.lng, 'speed': packet.speed, 'timestamp': Timestamp.fromDate(packet.timestamp)});
      if (route.length > 500) route.removeAt(0); // Keep last 500 points

      final avgSpeed = route.map((p) => (p['speed'] as num).toDouble()).reduce((a, b) => a + b) / route.length;

      await _db.collection('trips').doc(currentTripId).update({
        'route': route,
        'distanceKm': distKm,
        'maxSpeed': packet.speed > maxSpeed ? packet.speed : maxSpeed,
        'avgSpeed': avgSpeed,
        'harshBrakes': FieldValue.increment(packet.harshBrake ? 1 : 0),
        'harshAccelerations': FieldValue.increment(packet.harshAcceleration ? 1 : 0),
        'estimatedRevenue': Trip.calculateRevenue(distKm),
      });
    } else if (!isMoving && currentTripId != null) {
      // End trip
      await _db.collection('trips').doc(currentTripId).update({
        'endTime': Timestamp.fromDate(packet.timestamp),
        'isActive': false,
      });
      _activeTrip.remove(vehicleId);
    }
  }

  Future<void> _checkAlerts(GpsPacket packet, String vehicleId) async {
    final limit = _speedLimit[packet.gpsSerial] ?? 120.0;

    if (packet.speed > limit) {
      await _createAlert(
        type: AlertType.overspeed,
        severity: packet.speed > limit * 1.2 ? AlertSeverity.critical : AlertSeverity.warning,
        message: '${_serialToVehiclePlate[packet.gpsSerial]} exceeded ${limit.toInt()} km/h — ${packet.speed.toInt()} km/h recorded',
        vehicleId: vehicleId,
      );
    }

    if (packet.harshBrake) {
      await _createAlert(
        type: AlertType.harshBrake,
        severity: AlertSeverity.warning,
        message: '${_serialToVehiclePlate[packet.gpsSerial]} harsh braking detected',
        vehicleId: vehicleId,
      );
    }

    if (packet.harshAcceleration) {
      await _createAlert(
        type: AlertType.harshAcceleration,
        severity: AlertSeverity.warning,
        message: '${_serialToVehiclePlate[packet.gpsSerial]} harsh acceleration detected',
        vehicleId: vehicleId,
      );
    }
  }

  Future<void> _createAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String message,
    String? vehicleId,
    String? driverId,
  }) async {
    final alert = {
      'type': type.name,
      'severity': severity.name,
      'message': message,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'ownerId': _ownerId,
    };
    await _db.collection('alerts').add(alert);
    await _notifications.showAlert(message, severity);
  }

  /// Haversine distance formula (returns km)
  double _haversine(dynamic lat1, dynamic lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - (lat1 as num).toDouble());
    final dLng = _deg2rad(lng2 - (lng1 as num).toDouble());
    final a = _sinSq(dLat / 2) +
        _cosDeg((lat1 as num).toDouble()) * _cosDeg(lat2) * _sinSq(dLng / 2);
    final c = 2 * _atan2(a);
    return R * c;
  }

  double _deg2rad(double d) => d * (3.14159265358979 / 180);
  double _sinSq(double x) => _sin(x) * _sin(x);
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cosDeg(double deg) {
    final r = _deg2rad(deg);
    return 1 - (r * r) / 2 + (r * r * r * r) / 24;
  }
  double _atan2(double x) => x < 0.5 ? x * (1 - x / 3) : 1.5708 - (1 - x) / x;

  void dispose() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    _pollingTimer?.cancel();
    _packetStream.close();
  }
}
