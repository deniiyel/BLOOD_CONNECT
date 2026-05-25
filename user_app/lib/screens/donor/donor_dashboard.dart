import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/blood_group_badge.dart';
import '../../widgets/request_card.dart';
import '../shared/notifications_screen.dart';

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final donorProvider = context.watch<DonorProvider>();
    final requestProvider = context.watch<RequestProvider>();
    if (user == null) return const SizedBox.shrink();

    final donor = donorProvider.donorProfile;
    final pending = requestProvider.pendingDonorRequests;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('Blood Connect'),
              ],
            ),
            actions: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (pending.isNotEmpty)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(
                      isForDonor: true,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  _ProfileCard(user: user, donor: donor),
                  const SizedBox(height: 18),

                  // Stats row
                  _StatsRow(donor: donor),
                  const SizedBox(height: 24),

                  // Incoming requests header
                  Row(
                    children: [
                      Text(
                        'Incoming Requests',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      if (pending.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pending.length} new',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Requests list
                  if (donorProvider.isLoading && donor == null)
                    const Center(
                        child: CircularProgressIndicator())
                  else if (pending.isEmpty)
                    _EmptyRequests()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pending.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final req = pending[i];
                        return RequestCard(
                          request: req,
                          isDonorView: true,
                          onAccept: () async {
                            final ok = await context
                                .read<RequestProvider>()
                                .acceptRequest(req.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? '✓  Request accepted!'
                                    : 'Failed to accept'),
                                backgroundColor: ok
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                            );
                          },
                          onReject: () async {
                            final ok = await context
                                .read<RequestProvider>()
                                .rejectRequest(req.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    ok ? 'Request rejected' : 'Failed'),
                                backgroundColor: ok
                                    ? AppTheme.textSecondary
                                    : AppTheme.error,
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile card ───────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final DonorModel? donor;

  const _ProfileCard({required this.user, required this.donor});

  @override
  Widget build(BuildContext context) {
    final isAvailable = donor?.isAvailable ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (donor?.bloodGroup != null) ...[
                          BloodGroupBadge(
                            bloodGroup: donor!.bloodGroup,
                            isSmall: true,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (donor?.city != null)
                          Text(
                            donor!.city,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        if (donor == null)
                          Text(
                            'Profile incomplete',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAvailable
                      ? Colors.greenAccent
                      : Colors.white30,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability status',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      isAvailable
                          ? 'Available to donate'
                          : 'Not available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isAvailable,
                onChanged: donor != null
                    ? (v) async {
                        await context
                            .read<DonorProvider>()
                            .toggleAvailability(user.uid, v);
                      }
                    : null,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green,
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────

class _StatsRow extends StatelessWidget {
  final DonorModel? donor;
  const _StatsRow({this.donor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.favorite,
            label: 'Donations',
            value: '${donor?.totalDonations ?? 0}',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatItem(
            icon: Icons.calendar_today_rounded,
            label: 'Last donated',
            value: donor?.lastDonationDate != null
                ? DateFormat('MMM d').format(donor!.lastDonationDate!)
                : 'Never',
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatItem(
            icon: Icons.health_and_safety_outlined,
            label: 'Health',
            value: donor?.healthStatus ?? '—',
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border:
            Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────

class _EmptyRequests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No pending requests',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When recipients send you blood requests,\nthey will appear here.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
