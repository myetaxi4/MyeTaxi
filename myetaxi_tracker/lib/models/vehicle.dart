import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleStatus { moving, idle, offline }
enum CommType { sms, internet, both }

class Vehicle {
  final String id;
  final String name;
  final String plate;
  final String gpsSerial;
  final String ipAddress;
  final String? driverId;
  final double speedLimit;
  final VehicleStatus status;
  final double? lat;
  final double? lng;
  final double speed;
  final DateTime lastUpdate;
  final DateTime registrationExpiry;
  final DateTime insuranceExpiry;
  final CommType commType;
  final String ownerId;

  Vehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.gpsSerial,
    required this.ipAddress,
    this.driverId,
    required this.speedLimit,
    this.status = VehicleStatus.offline,
    this.lat,
    this.lng,
    this.speed = 0,
    required this.lastUpdate,
    required this.registrationExpiry,
    required this.insuranceExpiry,
    this.commType = CommType.both,
    required this.ownerId,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Vehicle(
      id: doc.id,
      name: d['name'] ?? '',
      plate: d['plate'] ?? '',
      gpsSerial: d['gpsSerial'] ?? '',
      ipAddress: d['ipAddress'] ?? '',
      driverId: d['driverId'],
      speedLimit: (d['speedLimit'] ?? 120).toDouble(),
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'offline'),
        orElse: () => VehicleStatus.offline,
      ),
      lat: d['lat']?.toDouble(),
      lng: d['lng']?.toDouble(),
      speed: (d['speed'] ?? 0).toDouble(),
      lastUpdate: (d['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registrationExpiry: (d['registrationExpiry'] as Timestamp).toDate(),
      insuranceExpiry: (d['insuranceExpiry'] as Timestamp).toDate(),
      commType: CommType.values.firstWhere(
        (e) => e.name == (d['commType'] ?? 'both'),
        orElse: () => CommType.both,
      ),
      ownerId: d['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'plate': plate,
    'gpsSerial': gpsSerial,
    'ipAddress': ipAddress,
    'driverId': driverId,
    'speedLimit': speedLimit,
    'status': status.name,
    'lat': lat,
    'lng': lng,
    'speed': speed,
    'lastUpdate': Timestamp.fromDate(lastUpdate),
    'registrationExpiry': Timestamp.fromDate(registrationExpiry),
    'insuranceExpiry': Timestamp.fromDate(insuranceExpiry),
    'commType': commType.name,
    'ownerId': ownerId,
  };

  Vehicle copyWith({
    double? lat, double? lng, double? speed,
    VehicleStatus? status, DateTime? lastUpdate, String? driverId,
  }) => Vehicle(
    id: id, name: name, plate: plate, gpsSerial: gpsSerial,
    ipAddress: ipAddress, speedLimit: speedLimit,
    registrationExpiry: registrationExpiry, insuranceExpiry: insuranceExpiry,
    commType: commType, ownerId: ownerId,
    driverId: driverId ?? this.driverId,
    lat: lat ?? this.lat, lng: lng ?? this.lng,
    speed: speed ?? this.speed,
    status: status ?? this.status,
    lastUpdate: lastUpdate ?? this.lastUpdate,
  );

  // Days until expiry helpers
  int get daysUntilRegistrationExpiry =>
      registrationExpiry.difference(DateTime.now()).inDays;
  int get daysUntilInsuranceExpiry =>
      insuranceExpiry.difference(DateTime.now()).inDays;
  bool get isRegistrationUrgent => daysUntilRegistrationExpiry <= 42;
  bool get isInsuranceUrgent => daysUntilInsuranceExpiry <= 42;
}
