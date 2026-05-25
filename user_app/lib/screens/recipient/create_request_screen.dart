import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class CreateRequestScreen extends StatefulWidget {
  final DonorModel? preSelectedDonor;
  final bool isEmergency;

  const CreateRequestScreen({
    super.key,
    this.preSelectedDonor,
    this.isEmergency = false,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedBloodGroup = 'O+';
  String _urgency = 'Normal';
  int _unitsNeeded = 1;
  int _expiryHours = 24;
  DonorModel? _selectedDonor;

  @override
  void initState() {
    super.initState();
    _selectedDonor = widget.preSelectedDonor;
    if (widget.isEmergency) {
      _urgency = 'Emergency';
      _expiryHours = 1;
    }
    if (widget.preSelectedDonor != null) {
      _selectedBloodGroup = widget.preSelectedDonor!.bloodGroup;
    }
    // Pre-fill contact with user's phone if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppAuthProvider>().user;
      if (user?.phone != null && _contactCtrl.text.isEmpty) {
        _contactCtrl.text = user!.phone!;
      }
    });
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _hospitalCtrl.dispose();
    _cityCtrl.dispose();
    _contactCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDonor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a donor first'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final user = context.read<AppAuthProvider>().user;
    if (user == null) return;

    final request = RequestModel(
      id: '',
      recipientId: user.uid,
      recipientName: user.fullName,
      recipientContact: _contactCtrl.text.trim(),
      donorId: _selectedDonor!.uid,
      donorName: _selectedDonor!.fullName,
      patientName: _patientNameCtrl.text.trim(),
      bloodGroup: _selectedBloodGroup,
      hospital: _hospitalCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      urgency: _urgency,
      status: 'pending',
      additionalNotes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: _expiryHours)),
      unitsNeeded: _unitsNeeded,
    );

    final ok = await context.read<RequestProvider>().createRequest(request);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓  Blood request sent successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      final err = context.read<RequestProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed to send request'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  /// Opens donor search to pick a donor
  Future<void> _pickDonor() async {
    final donorProvider = context.read<DonorProvider>();
    await donorProvider.searchDonors();
    if (!mounted) return;

    final donors = donorProvider.searchResults
        .where((donor) => donor.isAvailable)
        .toList();
    if (donors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No available donors found. Try searching first.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<DonorModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select a Donor',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: donors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final d = donors[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      side:
                          const BorderSide(color: AppTheme.border),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        d.bloodGroup,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(d.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text('${d.city} · ${d.bloodGroup}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: d.isAvailable
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, d),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDonor = picked;
        _selectedBloodGroup = picked.bloodGroup;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEmergency ? '🚨 Emergency Request' : 'Blood Request',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Emergency banner ───────────────
              if (_urgency == 'Emergency')
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.warningBg,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emergency_rounded,
                          color: AppTheme.warning, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Emergency request — the donor will see this highlighted.',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Donor selector ─────────────────
              _SectionLabel(
                  title: 'Select Donor', icon: Icons.person_search_outlined),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.preSelectedDonor == null ? _pickDonor : null,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: _selectedDonor == null
                          ? AppTheme.primary
                          : AppTheme.border,
                      width: _selectedDonor == null ? 2 : 1,
                    ),
                  ),
                  child: _selectedDonor == null
                      ? Row(
                          children: const [
                            Icon(Icons.add_circle_outline,
                                color: AppTheme.primary),
                            SizedBox(width: 12),
                            Text(
                              'Tap to select a donor',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryLight,
                              child: Text(
                                _selectedDonor!.bloodGroup,
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedDonor!.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedDonor!.city} · ${_selectedDonor!.bloodGroup}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.preSelectedDonor == null)
                              const Icon(Icons.swap_horiz_rounded,
                                  color: AppTheme.textMuted),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Request details ────────────────
              _SectionLabel(
                  title: 'Request Details',
                  icon: Icons.assignment_outlined),
              const SizedBox(height: 10),
              _FormCard(children: [
                TextFormField(
                  controller: _patientNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Patient name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'Patient name'),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBloodGroup,
                      decoration: const InputDecoration(
                        labelText: 'Blood group',
                        prefixIcon:
                            Icon(Icons.bloodtype_outlined),
                      ),
                      items: [
                        'A+', 'A-', 'B+', 'B-',
                        'AB+', 'AB-', 'O+', 'O-',
                      ]
                          .map((bg) => DropdownMenuItem(
                              value: bg, child: Text(bg)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBloodGroup = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _urgency,
                      decoration: const InputDecoration(
                        labelText: 'Urgency',
                        prefixIcon: Icon(Icons.priority_high_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Normal', child: Text('Normal')),
                        DropdownMenuItem(
                            value: 'Emergency',
                            child: Text('Emergency')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _urgency = v!;
                          _expiryHours = _urgency == 'Emergency' ? 1 : 24;
                        });
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _hospitalCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Hospital name',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'Hospital'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cityCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'City'),
                ),
              ]),
              const SizedBox(height: 22),

              // ── Contact & units ────────────────
              _SectionLabel(
                  title: 'Contact & Units',
                  icon: Icons.phone_outlined),
              const SizedBox(height: 10),
              _FormCard(children: [
                TextFormField(
                  controller: _contactCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Recipient\'s phone',
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),

                // Units needed stepper
                Row(
                  children: [
                    const Icon(Icons.water_drop_outlined,
                        color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Units needed',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '$_unitsNeeded unit${_unitsNeeded == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _StepperButton(
                          icon: Icons.remove,
                          onTap: _unitsNeeded > 1
                              ? () => setState(
                                  () => _unitsNeeded--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          child: Text(
                            '$_unitsNeeded',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StepperButton(
                          icon: Icons.add,
                          onTap: _unitsNeeded < 10
                              ? () => setState(
                                  () => _unitsNeeded++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _expiryHours,
                  decoration: const InputDecoration(
                    labelText: 'Request expires after',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 hour')),
                    DropdownMenuItem(value: 3, child: Text('3 hours')),
                    DropdownMenuItem(value: 6, child: Text('6 hours')),
                    DropdownMenuItem(value: 12, child: Text('12 hours')),
                    DropdownMenuItem(value: 24, child: Text('24 hours')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _expiryHours = value);
                    }
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional notes (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ]),
              const SizedBox(height: 32),

              // ── Submit ─────────────────────────
              ElevatedButton.icon(
                onPressed: rp.isLoading ? null : _submit,
                icon: rp.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label:
                    Text(rp.isLoading ? 'Sending…' : 'Send request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _urgency == 'Emergency'
                      ? AppTheme.warning
                      : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primaryLight
              : AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppTheme.primary : AppTheme.textMuted,
        ),
      ),
    );
  }
}
