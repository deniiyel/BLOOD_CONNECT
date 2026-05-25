import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/blood_group_badge.dart';
import 'create_request_screen.dart';

class DonorDetailScreen extends StatelessWidget {
  final DonorModel donor;

  const DonorDetailScreen({super.key, required this.donor});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero ──────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.brandGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 44),
                          ),
                          BloodGroupBadge(bloodGroup: donor.bloodGroup),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        donor.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 14),
                          const SizedBox(width: 4),
                          Text(
                            donor.city,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        icon: Icons.circle,
                        label: donor.isAvailable
                            ? 'Available'
                            : 'Unavailable',
                        color: donor.isAvailable
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                      _Badge(
                        icon: Icons.health_and_safety_outlined,
                        label: donor.healthStatus,
                        color: donor.healthStatus == 'Healthy'
                            ? AppTheme.info
                            : AppTheme.warning,
                      ),
                      if (donor.canDonate)
                        _Badge(
                          icon: Icons.check_circle_outline,
                          label: 'Ready to donate',
                          color: AppTheme.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Personal details
                  _InfoCard(
                    title: 'Personal Details',
                    icon: Icons.person_outline,
                    rows: [
                      _Row('Full name', donor.fullName),
                      _Row('Age', '${donor.age} years'),
                      _Row('Gender', donor.gender),
                      _Row('Phone', donor.phone),
                      _Row('City', donor.city),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Medical details
                  _InfoCard(
                    title: 'Medical Information',
                    icon: Icons.medical_information_outlined,
                    rows: [
                      _Row('Blood group', donor.bloodGroup),
                      _Row('Weight', '${donor.weight} kg'),
                      _Row('Health status', donor.healthStatus),
                      if (donor.diseases?.isNotEmpty == true)
                        _Row('Conditions', donor.diseases!),
                      _Row(
                        'Last donated',
                        donor.lastDonationDate != null
                            ? DateFormat('MMMM d, y')
                                .format(donor.lastDonationDate!)
                            : 'Never donated',
                      ),
                      _Row('Total donations',
                          '${donor.totalDonations} times'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Eligibility warning
                  if (!donor.canDonate)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warningBg,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color:
                              AppTheme.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppTheme.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Donor may not be eligible right now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warning,
                                    fontSize: 13,
                                  ),
                                ),
                                if (!donor.canDonateAgain)
                                  const Text(
                                    'Last donation was less than 56 days ago',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Send request button
                  ElevatedButton.icon(
                    onPressed: (user != null && donor.isAvailable)
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateRequestScreen(
                                  preSelectedDonor: donor,
                                ),
                              ),
                            )
                        : null,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send blood request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: donor.isAvailable
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                  if (!donor.isAvailable) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'This donor is currently unavailable',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal widgets ───────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Row> rows;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
