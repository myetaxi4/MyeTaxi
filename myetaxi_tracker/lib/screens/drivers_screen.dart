import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/fleet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/driver.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Drivers')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddDriverScreen())),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver',
          style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: driversAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (drivers) {
          if (drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline,
                    color: AppTheme.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No drivers added', style: AppTextStyles.label),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: drivers.length,
            padding: const EdgeInsets.only(bottom: 100),
            itemBuilder: (_, i) => _DriverCard(driver: drivers[i]),
          );
        },
      ),
    );
  }
}

class _DriverCard extends ConsumerWidget {
  final Driver driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider).value ?? [];
    final assignedVehicle = vehicles.firstWhere(
      (v) => v.id == driver.assignedVehicleId,
      orElse: () => throw Exception(),
    );
    final vehicleName = driver.assignedVehicleId != null
        ? assignedVehicle?.plate ?? 'Assigned'
        : 'No Vehicle';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.accent.withOpacity(0.15),
                backgroundImage: driver.photoUrl != null
                    ? NetworkImage(driver.photoUrl!)
                    : null,
                child: driver.photoUrl == null
                    ? Text(driver.initials,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                    Text(driver.phone,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                    Text(driver.email,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              DriverScoreRing(score: driver.driverScore),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Router ID',
                  value: driver.routerId,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoBox(
                  label: 'License #',
                  value: driver.licenseNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Assigned Vehicle',
                  value: vehicleName,
                  valueColor: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoBox(
                  label: 'Score',
                  value: '${driver.driverScore.toInt()} / 100',
                  valueColor: driver.driverScore >= 80
                      ? AppTheme.green
                      : driver.driverScore >= 60
                          ? AppTheme.orange
                          : AppTheme.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(text: driver.licenseNumber, color: AppTheme.accent),
              ExpiryChip(expiry: driver.licenseExpiry, label: 'License'),
            ],
          ),
          const SizedBox(height: 8),
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
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('EDIT'),
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => AddDriverScreen(existing: driver))),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                onPressed: () => _confirmDelete(context, driver.id),
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
        title: const Text('Delete Driver?'),
        content: Text('Remove ${driver.name} from your fleet?',
          style: const TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              FleetRepository.deleteDriver(id);
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

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.label.copyWith(fontSize: 9)),
          const SizedBox(height: 3),
          Text(value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── ADD / EDIT DRIVER FORM ───────────────────────────────────────────────────

class AddDriverScreen extends ConsumerStatefulWidget {
  final Driver? existing;
  const AddDriverScreen({super.key, this.existing});

  @override
  ConsumerState<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends ConsumerState<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _phone, _email, _routerId, _license;
  DateTime? _licenseExpiry;
  String? _assignedVehicle;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _name = TextEditingController(text: d?.name ?? '');
    _phone = TextEditingController(text: d?.phone ?? '');
    _email = TextEditingController(text: d?.email ?? '');
    _routerId = TextEditingController(text: d?.routerId ?? '');
    _license = TextEditingController(text: d?.licenseNumber ?? '');
    _licenseExpiry = d?.licenseExpiry;
    _assignedVehicle = d?.assignedVehicleId;
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider).value ?? [];
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Driver' : 'Add Driver'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(isEditing ? 'EDIT DRIVER DETAILS' : 'NEW DRIVER',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            LabeledField(label: 'Full Name',
              child: TextFormField(controller: _name,
                decoration: const InputDecoration(hintText: 'Driver full name'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null)),

            LabeledField(label: 'Phone Number',
              child: TextFormField(controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+971 50 000 0000'))),

            LabeledField(label: 'Email',
              child: TextFormField(controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'driver@email.com'))),

            LabeledField(label: 'Router ID',
              child: TextFormField(controller: _routerId,
                decoration: const InputDecoration(hintText: 'RTR-003'))),

            LabeledField(label: 'Driving License Number',
              child: TextFormField(controller: _license,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'DL-UAE-XXXXXX'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null)),

            LabeledField(label: 'Driving License Expiry Date',
              child: _DatePickerField(
                value: _licenseExpiry,
                hint: 'Select license expiry',
                onChanged: (d) => setState(() => _licenseExpiry = d))),

            LabeledField(
              label: 'Assign to Vehicle',
              child: DropdownButtonFormField<String>(
                value: _assignedVehicle,
                dropdownColor: AppTheme.card,
                decoration: const InputDecoration(hintText: '— No Vehicle —'),
                items: [
                  const DropdownMenuItem(value: null,
                    child: Text('— No Vehicle —')),
                  ...vehicles.map((v) => DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.name} (${v.plate})'))),
                ],
                onChanged: (v) => setState(() => _assignedVehicle = v),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _loading ? null : () => _submit(uid, isEditing),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : Text(
                      isEditing ? 'SAVE CHANGES' : 'ADD DRIVER',
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
    if (_licenseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set license expiry date')));
      return;
    }

    setState(() => _loading = true);
    try {
      final driver = Driver(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        routerId: _routerId.text.trim(),
        licenseNumber: _license.text.trim().toUpperCase(),
        licenseExpiry: _licenseExpiry!,
        assignedVehicleId: _assignedVehicle,
        driverScore: widget.existing?.driverScore ?? 100.0,
        ownerId: ownerId,
      );

      if (isEditing) {
        await FleetRepository.updateDriver(driver.id, driver.toFirestore());
      } else {
        await FleetRepository.addDriver(driver);
        // If driver was assigned to a vehicle, update the vehicle record
        if (_assignedVehicle != null) {
          await FleetRepository.updateVehicle(
            _assignedVehicle!, {'driverId': driver.id});
        }
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
          border: Border.all(
              color: value != null ? AppTheme.accent : AppTheme.border),
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
                color: value != null
                    ? AppTheme.textPrimary
                    : AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
