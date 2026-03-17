import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String routerId;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String? assignedVehicleId;
  final String? photoUrl;
  final double driverScore;
  final String ownerId;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.routerId,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.assignedVehicleId,
    this.photoUrl,
    this.driverScore = 100.0,
    required this.ownerId,
  });

  factory Driver.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Driver(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'] ?? '',
      routerId: d['routerId'] ?? '',
      licenseNumber: d['licenseNumber'] ?? '',
      licenseExpiry: (d['licenseExpiry'] as Timestamp).toDate(),
      assignedVehicleId: d['assignedVehicleId'],
      photoUrl: d['photoUrl'],
      driverScore: (d['driverScore'] ?? 100).toDouble(),
      ownerId: d['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'phone': phone,
    'email': email,
    'routerId': routerId,
    'licenseNumber': licenseNumber,
    'licenseExpiry': Timestamp.fromDate(licenseExpiry),
    'assignedVehicleId': assignedVehicleId,
    'photoUrl': photoUrl,
    'driverScore': driverScore,
    'ownerId': ownerId,
  };

  int get daysUntilLicenseExpiry =>
      licenseExpiry.difference(DateTime.now()).inDays;
  bool get isLicenseUrgent => daysUntilLicenseExpiry <= 42;
  String get initials => name.isNotEmpty
      ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
      : '?';
}
