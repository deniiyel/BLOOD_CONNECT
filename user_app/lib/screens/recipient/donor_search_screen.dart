import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/donor_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/blood_group_badge.dart';
import '../../widgets/shimmer_widgets.dart';
import 'donor_detail_screen.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> {
  final _cityCtrl = TextEditingController();
  String? _selectedBloodGroup;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Screen load hote hi automatic saare donors fetch karne ke liye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyFilter();
    });
  }

  /// One-shot search aur live search dono properties ko trigger karega taake state crash na ho
  void _applyFilter() {
    final cityText = _cityCtrl.text.trim();
    context.read<DonorProvider>().searchDonors(
          bloodGroup: _selectedBloodGroup,
          city: cityText.isEmpty ? null : cityText,
        );
  }

  /// Debounced version taake har keystroke par Firestore hit na ho
  void _applyFilterDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _applyFilter();
    });
  }

  void _clearFilters() {
    _debounce?.cancel();
    _cityCtrl.clear();
    setState(() {
      _selectedBloodGroup = null;
    });
    _applyFilter();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DonorProvider>();
    
    final hasFilter = _selectedBloodGroup != null || _cityCtrl.text.trim().isNotEmpty;
    final donors = hasFilter ? dp.searchResults : dp.availableDonors;

    return Scaffold(
      appBar: AppBar(title: const Text('Find Donors')),
      body: Column(
        children: [
          // ── Filter panel ──────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: const Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Blood group dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // FIX: initialValue hata kar direct 'value' lagaya hai real-time binding ke liye
                        value: _selectedBloodGroup,
                        decoration: InputDecoration(
                          labelText: 'Blood group',
                          prefixIcon: const Icon(
                              Icons.bloodtype_outlined,
                              size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                        ),
                        hint: const Text('Any'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Any')),
                          ...AppConstants.bloodGroups.map(
                            (bg) => DropdownMenuItem(
                                value: bg, child: Text(bg)),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedBloodGroup = v);
                          _applyFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // City field
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'City',
                          prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          suffixIcon: _cityCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _cityCtrl.clear();
                                    setState(() {});
                                    _applyFilter();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _applyFilterDebounced();
                        },
                      ),
                    ),
                  ],
                ),

                // Active filter chips + clear
                if (hasFilter) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_selectedBloodGroup != null)
                        _FilterChip(label: _selectedBloodGroup!),
                      if (_cityCtrl.text.trim().isNotEmpty)
                        _FilterChip(label: _cityCtrl.text.trim()),
                      const Spacer(),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Results ───────────────────────────
          Expanded(
            child: dp.error != null
                ? _SearchError(message: dp.error!)
                : dp.isSearching
                    ? const ShimmerList(itemCount: 5)
                    : donors.isEmpty
                        ? _EmptySearch(hasFilter: hasFilter)
                        : _DonorList(donors: donors),
          ),
        ],
      ),
    );
  }
}

// ── Search error ───────────────────────────────

class _SearchError extends StatelessWidget {
  final String message;
  const _SearchError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Search failed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Donor list ─────────────────────────────────

class _DonorList extends StatelessWidget {
  final List<DonorModel> donors;
  const _DonorList({required this.donors});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: donors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _DonorCard(donor: donors[i]),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final DonorModel donor;
  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonorDetailScreen(donor: donor),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppTheme.primary, size: 28),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: BloodGroupBadge(
                    bloodGroup: donor.bloodGroup,
                    isSmall: true,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        donor.city,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.cake_outlined,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${donor.age}y',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: donor.isAvailable
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        donor.isAvailable ? 'Available' : 'Not available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: donor.isAvailable
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                      ),
                      if (donor.totalDonations > 0) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.favorite_rounded,
                            size: 12, color: AppTheme.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${donor.totalDonations} donation${donor.totalDonations == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final bool hasFilter;
  const _EmptySearch({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter
                  ? Icons.search_off_rounded
                  : Icons.bloodtype_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'No donors found' : 'No donors available',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try adjusting your filters or searching a different city.'
                  : 'No donors are currently available. Check back soon.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AppConstants bloodGroups ───────────────────
class AppConstants {
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
}