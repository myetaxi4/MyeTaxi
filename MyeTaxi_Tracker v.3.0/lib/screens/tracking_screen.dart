import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/fleet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/vehicle.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  const TrackingScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  bool _followVehicle = true;

  static const _mapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#0a0e1a"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#5a7a9a"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0e1a"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2235"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1e2d45"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#060d1a"}]}
  ]''';

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleProvider(widget.vehicleId));
    final driversAsync = ref.watch(driversProvider);
    final tripsAsync = ref.watch(vehicleTripsProvider(widget.vehicleId));

    return vehicleAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: Text('Error: $e')),
      ),
      data: (vehicle) {
        if (vehicle == null) {
          return const Scaffold(
            backgroundColor: AppTheme.bg,
            body: Center(child: Text('Vehicle not found')),
          );
        }

        final driver = driversAsync.value?.firstWhere(
          (d) => d.id == vehicle.driverId,
          orElse: () => throw Exception(),
        );

        final hasLocation = vehicle.lat != null && vehicle.lng != null;
        final latLng = hasLocation
            ? LatLng(vehicle.lat!, vehicle.lng!)
            : const LatLng(25.2048, 55.2708);

        if (_followVehicle && _mapController != null && hasLocation) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(latLng),
          );
        }

        final trips = tripsAsync.value ?? [];
        final activeTrip = trips.isNotEmpty && trips.first.isActive ? trips.first : null;

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            title: Text(vehicle.name),
            actions: [
              IconButton(
                icon: Icon(
                  _followVehicle ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: _followVehicle ? AppTheme.accent : AppTheme.textMuted,
                ),
                onPressed: () => setState(() => _followVehicle = !_followVehicle),
                tooltip: 'Follow vehicle',
              ),
            ],
          ),
          body: Column(
            children: [
              // Map section
              SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: latLng,
                        zoom: 15,
                      ),
                      onMapCreated: (ctrl) {
                        _mapController = ctrl;
                        ctrl.setMapStyle(_mapStyle);
                      },
                      markers: hasLocation
                          ? {
                              Marker(
                                markerId: const MarkerId('vehicle'),
                                position: latLng,
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  vehicle.status == VehicleStatus.moving
                                      ? BitmapDescriptor.hueGreen
                                      : BitmapDescriptor.hueYellow,
                                ),
                                infoWindow: InfoWindow(
                                  title: vehicle.name,
                                  snippet:
                                      '${vehicle.speed.toInt()} km/h · ${vehicle.plate}',
                                ),
                              ),
                            }
                          : {},
                      polylines: activeTrip != null && activeTrip.route.isNotEmpty
                          ? {
                              Polyline(
                                polylineId: const PolylineId('route'),
                                color: AppTheme.accent,
                                width: 3,
                                points: activeTrip.route
                                    .map((p) => LatLng(p.lat, p.lng))
                                    .toList(),
                              ),
                            }
                          : {},
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                    // LIVE indicator
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            LiveDot(color: AppTheme.green, size: 7),
                            SizedBox(width: 5),
                            Text('LIVE',
                              style: TextStyle(
                                color: AppTheme.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Comm source badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.cell_tower,
                                size: 12, color: AppTheme.accent),
                            SizedBox(width: 4),
                            Text('SMS + NET',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable info panel
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Speed & status row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          SpeedGaugeWidget(
                            speed: vehicle.speed,
                            limit: vehicle.speedLimit,
                            size: 90,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow('Status',
                                    vehicle.status.name.toUpperCase(),
                                    vehicleStatusColor(vehicle.status)),
                                _InfoRow('Speed Limit',
                                    '${vehicle.speedLimit.toInt()} km/h',
                                    AppTheme.textPrimary),
                                _InfoRow('GPS Serial', vehicle.gpsSerial,
                                    AppTheme.accent),
                                _InfoRow('IP Address', vehicle.ipAddress,
                                    AppTheme.textMuted),
                                _InfoRow('Coords',
                                    vehicle.lat != null
                                        ? '${vehicle.lat!.toStringAsFixed(4)}, ${vehicle.lng!.toStringAsFixed(4)}'
                                        : 'Awaiting GPS',
                                    AppTheme.textMuted),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active trip card
                    if (activeTrip != null) ...[
                      const SectionHeader(title: 'Active Trip'),
                      AppCard(
                        borderColor: AppTheme.green.withOpacity(0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('IN PROGRESS',
                                      style: const TextStyle(
                                        color: AppTheme.green,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(activeTrip.durationFormatted,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'AED ${activeTrip.estimatedRevenue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppTheme.green,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      '${activeTrip.distanceKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: [
                                StatusBadge(
                                    text: 'Avg ${activeTrip.avgSpeed.toInt()} km/h',
                                    color: AppTheme.accent),
                                if (activeTrip.harshBrakes > 0)
                                  StatusBadge(
                                      text:
                                          '${activeTrip.harshBrakes} harsh brake',
                                      color: AppTheme.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Driver card
                    if (driver != null) ...[
                      const SectionHeader(title: 'Current Driver'),
                      AppCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.accent.withOpacity(0.2),
                              child: Text(driver.initials,
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driver.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(driver.phone,
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      StatusBadge(
                                          text: driver.licenseNumber,
                                          color: AppTheme.accent),
                                      ExpiryChip(
                                          expiry: driver.licenseExpiry,
                                          label: 'License'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DriverScoreRing(score: driver.driverScore),
                          ],
                        ),
                      ),
                    ],

                    // Document expiry
                    const SectionHeader(title: 'Documents'),
                    AppCard(
                      child: Column(
                        children: [
                          _DocRow('Registration',
                              vehicle.registrationExpiry),
                          const Divider(color: AppTheme.border, height: 16),
                          _DocRow('Insurance', vehicle.insuranceExpiry),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String label;
  final DateTime expiry;

  const _DocRow(this.label, this.expiry);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        ExpiryChip(expiry: expiry, label: label),
      ],
    );
  }
}
