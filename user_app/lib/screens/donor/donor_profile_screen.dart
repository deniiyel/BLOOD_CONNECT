import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _diseasesController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'O+';
  String _selectedHealthStatus = 'Healthy';
  DateTime? _lastDonationDate;
  bool _isAvailable = true;
  bool _isEditMode = false;
  bool _isInitialized = false;

  DonorProvider? _donorProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AppAuthProvider>().user?.uid;
      if (uid == null) return;
      _donorProvider = context.read<DonorProvider>();
      _donorProvider!.watchDonorProfile(uid);
      _donorProvider!.addListener(_onDonorProfileChanged);
      _applyDonorFromProvider();
    });
  }

  void _onDonorProfileChanged() {
    if (!mounted) return;
    // Don't overwrite fields while user is actively typing
    final hasFocus = FocusManager.instance.primaryFocus?.hasFocus ?? false;
    if (hasFocus) return;
    _applyDonorFromProvider();
  }

  void _applyDonorFromProvider() {
    final donor = context.read<DonorProvider>().donorProfile;
    final user = context.read<AppAuthProvider>().user;

    if (donor != null) {
      _nameController.text = donor.fullName;
      _phoneController.text = donor.phone;
      _cityController.text = donor.city;
      _ageController.text = donor.age.toString();
      _weightController.text = donor.weight.toString();
      _diseasesController.text = donor.diseases ?? '';
      setState(() {
        _selectedGender = donor.gender;
        _selectedBloodGroup = donor.bloodGroup;
        _selectedHealthStatus = donor.healthStatus;
        _lastDonationDate = donor.lastDonationDate;
        _isAvailable = donor.isAvailable;
        _isEditMode = true;
        _isInitialized = true;
      });
    } else {
      if (user != null && _nameController.text.isEmpty) {
        _nameController.text = user.fullName;
      }
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryRed),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _lastDonationDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AppAuthProvider>().user;
    if (user == null) return;

    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;

    final donor = DonorModel(
      uid: user.uid,
      email: user.email,
      fullName: _nameController.text.trim(),
      age: age,
      gender: _selectedGender,
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      weight: weight,
      healthStatus: _selectedHealthStatus,
      diseases: _diseasesController.text.trim().isEmpty
          ? null
          : _diseasesController.text.trim(),
      lastDonationDate: _lastDonationDate,
      isAvailable: _isAvailable,
      updatedAt: DateTime.now(),
    );

    // DonorProvider manages its own isLoading — no local _isSaving needed
    final success =
        await context.read<DonorProvider>().saveDonorProfile(donor);
    if (!mounted) return;

    final errorMsg = context.read<DonorProvider>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✓  Profile saved successfully!'
              : (errorMsg ?? 'Failed to save profile'),
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        duration: Duration(seconds: success ? 3 : 6),
      ),
    );
    if (success) setState(() => _isEditMode = true);
  }

  @override
  void dispose() {
    _donorProvider?.removeListener(_onDonorProfileChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _diseasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<DonorProvider>();

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'My Profile' : 'Complete Profile'),
        actions: [
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppTheme.success, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Profile saved',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isEditMode
                          ? 'Your Donor Profile'
                          : 'Complete Your Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _isEditMode
                          ? 'Keep your information up to date'
                          : 'Help us connect you with recipients',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Personal info ──────────────────────
              _SectionLabel(
                  title: 'Personal Information',
                  icon: Icons.person_outline),
              const SizedBox(height: 10),
              _FormCard(children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'Full name'),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: Validators.age,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: AppConstants.genders
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedGender = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'City'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Medical info ───────────────────────
              _SectionLabel(
                  title: 'Medical Information',
                  icon: Icons.medical_information_outlined),
              const SizedBox(height: 10),
              _FormCard(children: [
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBloodGroup,
                      decoration: const InputDecoration(
                        labelText: 'Blood group',
                        prefixIcon: Icon(Icons.bloodtype_outlined),
                      ),
                      items: AppConstants.bloodGroups
                          .map((bg) =>
                              DropdownMenuItem(value: bg, child: Text(bg)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBloodGroup = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      validator: Validators.weight,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedHealthStatus,
                  decoration: const InputDecoration(
                    labelText: 'Health status',
                    prefixIcon: Icon(Icons.health_and_safety_outlined),
                  ),
                  items: AppConstants.healthStatuses
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedHealthStatus = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _diseasesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Conditions / diseases (if any)',
                    prefixIcon: Icon(Icons.sick_outlined),
                    hintText: 'e.g. Diabetes, Hypertension…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),

                // Last donation date picker
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last donation date',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12),
                            ),
                            Text(
                              _lastDonationDate != null
                                  ? DateFormat('MMMM d, y')
                                      .format(_lastDonationDate!)
                                  : 'Never donated before',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Availability ───────────────────────
              _SectionLabel(
                  title: 'Availability',
                  icon: Icons.access_time_outlined),
              const SizedBox(height: 10),
              _FormCard(children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available to donate?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isAvailable
                              ? 'Recipients can find and contact you'
                              : 'You won\'t appear in search results',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeThumbColor: AppTheme.primary,
                  ),
                ]),
                const SizedBox(height: 14),
                const _NotificationOption(),
              ]),
              const SizedBox(height: 32),

              // ── Save button ────────────────────────
              Consumer<DonorProvider>(
                builder: (_, dp, __) => ElevatedButton(
                  onPressed: dp.isLoading ? null : _saveProfile,
                  child: dp.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update profile' : 'Save profile'),
                ),
              ),
              const SizedBox(height: 12),

              // ── Logout ─────────────────────────────
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log out'),
                      content: const Text(
                          'Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Log out',
                              style:
                                  TextStyle(color: AppTheme.primary)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<AppAuthProvider>().logout();
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
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
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _NotificationOption extends StatelessWidget {
  const _NotificationOption();

  Future<void> _toggle(BuildContext context, bool enabled) async {
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.setNotificationsEnabled(enabled);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (enabled ? 'Notifications enabled' : 'Notifications disabled')
              : (auth.error ?? 'Could not update notifications'),
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final enabled = auth.user?.notificationsEnabled ?? true;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: AppTheme.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Incoming requests and status alerts',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: enabled,
          onChanged: auth.isLoading ? null : (value) => _toggle(context, value),
          activeThumbColor: AppTheme.primary,
        ),
      ],
    );
  }
}
