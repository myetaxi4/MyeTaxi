import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/fleet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/vehicle.dart';
import 'tracking_screen.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('My Fleet')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RegisterVehicleScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Register Vehicle',
          style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car_outlined,
                    color: AppTheme.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No vehicles registered',
                    style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  const Text('Tap + Register Vehicle to get started',
                    style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: vehicles.length,
            padding: const EdgeInsets.only(bottom: 100),
            itemBuilder: (_, i) => _VehicleListCard(vehicle: vehicles[i]),
          );
        },
      ),
    );
  }
}

class _VehicleListCard extends ConsumerWidget {
  final Vehicle vehicle;
  const _VehicleListCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(driversProvider).value ?? [];
    final driver = drivers.firstWhere(
      (d) => d.id == vehicle.driverId,
      orElse: () => throw Exception(),
    );
    final driverName = vehicle.driverId != null ? driver?.name ?? 'Assigned' : 'No Driver';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      vehicleStatusColor(vehicle.status).withOpacity(0.3),
                      vehicleStatusColor(vehicle.status).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: vehicleStatusColor(vehicle.status).withOpacity(0.4)),
                ),
                child: Icon(Icons.directions_car,
                  color: vehicleStatusColor(vehicle.status), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    Text('${vehicle.plate} · $driverName',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              StatusBadge(
                text: vehicle.status.name.toUpperCase(),
                color: vehicleStatusColor(vehicle.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GridRow(items: [
            _GridItem('GPS Serial', vehicle.gpsSerial),
            _GridItem('IP Address', vehicle.ipAddress),
            _GridItem('Speed Limit', '${vehicle.speedLimit.toInt()} km/h'),
            _GridItem('Comm Type', vehicle.commType.name.toUpperCase()),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ExpiryChip(expiry: vehicle.registrationExpiry, label: 'Reg'),
              ExpiryChip(expiry: vehicle.insuranceExpiry, label: 'Ins'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: const Text('TRACK LIVE'),
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => TrackingScreen(vehicleId: vehicle.id))),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.textMuted),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => RegisterVehicleScreen(existing: vehicle))),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                onPressed: () => _confirmDelete(context, vehicle.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Vehicle?'),
        content: Text('Remove ${vehicle.name} from your fleet?',
          style: const TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              FleetRepository.deleteVehicle(id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
              style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  final List<_GridItem> items;
  const _GridRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 6,
      children: items.map((item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.label, style: AppTextStyles.label.copyWith(fontSize: 9)),
            Text(item.value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _GridItem {
  final String label;
  final String value;
  const _GridItem(this.label, this.value);
}

// ─── REGISTER / EDIT VEHICLE FORM ─────────────────────────────────────────────

class RegisterVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle? existing;
  const RegisterVehicleScreen({super.key, this.existing});

  @override
  ConsumerState<RegisterVehicleScreen> createState() =>
      _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends ConsumerState<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _plate, _serial, _ip, _limit;
  CommType _commType = CommType.both;
  DateTime? _regExpiry;
  DateTime? _insExpiry;
  String? _assignedDriver;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _name = TextEditingController(text: v?.name ?? '');
    _plate = TextEditingController(text: v?.plate ?? '');
    _serial = TextEditingController(text: v?.gpsSerial ?? '');
    _ip = TextEditingController(text: v?.ipAddress ?? '');
    _limit = TextEditingController(text: v?.speedLimit.toInt().toString() ?? '120');
    _commType = v?.commType ?? CommType.both;
    _regExpiry = v?.registrationExpiry;
    _insExpiry = v?.insuranceExpiry;
    _assignedDriver = v?.driverId;
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driversProvider).value ?? [];
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle' : 'Register Vehicle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(isEditing ? 'EDIT VEHICLE DETAILS' : 'NEW VEHICLE REGISTRATION',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            LabeledField(
              label: 'Vehicle Name / Model',
              child: TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  hintText: 'e.g. Toyota Camry 2024'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ),

            LabeledField(
              label: 'License Plate',
              child: TextFormField(
                controller: _plate,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'e.g. ABC-1234'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ),

            LabeledField(
              label: 'GPS Serial Number',
              child: TextFormField(
                controller: _serial,
                decoration: const InputDecoration(
                  hintText: 'e.g. GPS-TK-003',
                  prefixIcon: Icon(Icons.gps_fixed, color: AppTheme.textMuted)),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ),

            LabeledField(
              label: 'GPS IP Address (for Internet mode)',
              child: TextFormField(
                controller: _ip,
                decoration: const InputDecoration(
                  hintText: 'e.g. 192.168.1.103',
                  prefixIcon: Icon(Icons.wifi, color: AppTheme.textMuted)),
              ),
            ),

            LabeledField(
              label: 'Speed Limit (km/h)',
              child: TextFormField(
                controller: _limit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '120',
                  prefixIcon: Icon(Icons.speed, color: AppTheme.textMuted)),
                validator: (v) =>
                  int.tryParse(v ?? '') == null ? 'Enter valid number' : null,
              ),
            ),

            LabeledField(
              label: 'Communication Type',
              child: Row(
                children: CommType.values.map((t) {
                  final selected = _commType == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _commType = t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.accent.withOpacity(0.15)
                              : const Color(0xFF0D1520),
                          border: Border.all(
                            color: selected ? AppTheme.accent : AppTheme.border,
                            width: selected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? AppTheme.accent : AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Assign driver
            LabeledField(
              label: 'Assign Driver',
              child: DropdownButtonFormField<String>(
                value: _assignedDriver,
                dropdownColor: AppTheme.card,
                decoration: const InputDecoration(
                  hintText: '— No Driver —'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— No Driver —')),
                  ...drivers.map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name),
                  )),
                ],
                onChanged: (v) => setState(() => _assignedDriver = v),
              ),
            ),

            // Registration expiry
            LabeledField(
              label: 'Registration Expiry Date',
              child: _DatePickerField(
                value: _regExpiry,
                hint: 'Select registration expiry',
                onChanged: (d) => setState(() => _regExpiry = d),
              ),
            ),

            // Insurance expiry
            LabeledField(
              label: 'Insurance Expiry Date',
              child: _DatePickerField(
                value: _insExpiry,
                hint: 'Select insurance expiry',
                onChanged: (d) => setState(() => _insExpiry = d),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _loading ? null : () => _submit(uid, isEditing),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : Text(
                      isEditing ? 'SAVE CHANGES' : 'REGISTER VEHICLE',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(String ownerId, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;
    if (_regExpiry == null || _insExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set expiry dates')));
      return;
    }

    setState(() => _loading = true);
    try {
      final vehicle = Vehicle(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _name.text.trim(),
        plate: _plate.text.trim().toUpperCase(),
        gpsSerial: _serial.text.trim(),
        ipAddress: _ip.text.trim(),
        driverId: _assignedDriver,
        speedLimit: double.parse(_limit.text),
        status: VehicleStatus.offline,
        lastUpdate: DateTime.now(),
        registrationExpiry: _regExpiry!,
        insuranceExpiry: _insExpiry!,
        commType: _commType,
        ownerId: ownerId,
      );

      if (isEditing) {
        await FleetRepository.updateVehicle(
            vehicle.id, vehicle.toFirestore());
      } else {
        await FleetRepository.addVehicle(vehicle);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _loading = false);
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
          builder: (_, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.accent,
                surface: AppTheme.card,
                background: AppTheme.bg,
              ),
            ),
            child: child!,
          ),
        );
        if (d != null) onChanged(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1520),
          border: Border.all(color: value != null ? AppTheme.accent : AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
              size: 16,
              color: value != null ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? DateFormat('dd MMM yyyy').format(value!)
                  : hint,
              style: TextStyle(
                color: value != null ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
