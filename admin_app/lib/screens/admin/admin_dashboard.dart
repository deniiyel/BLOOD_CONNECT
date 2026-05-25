import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_card.dart';

class AdminDashboard extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const AdminDashboard({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Hero banner ──────────────────────────
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppTheme.adminGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppTheme.adminPrimary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Platform overview',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Admin Console',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Monitor users, donors, and request activity. '
                'Remove profiles when needed.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Stats grid ───────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatCard(
              label: 'Registered users',
              value: '${admin.userCount}',
              icon: Icons.person_outline,
              color: AppTheme.info,
            ),
            StatCard(
              label: 'Donor profiles',
              value: '${admin.donorCount}',
              icon: Icons.bloodtype_outlined,
              color: AppTheme.primary,
            ),
            StatCard(
              label: 'Total requests',
              value: '${admin.requestCount}',
              icon: Icons.inbox_outlined,
              color: AppTheme.adminPrimary,
            ),
            StatCard(
              label: 'Emergency',
              value: '${admin.emergencyCount}',
              icon: Icons.schedule_rounded,
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ── Quick actions card ───────────────────
        const SectionHeader(
          title: 'Quick actions',
          subtitle: 'Open the admin workspace you need',
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.people_outline,
                title: 'People & profiles',
                subtitle: 'Search, filter, suspend, or delete accounts',
                iconBg: AppTheme.infoBg,
                iconColor: AppTheme.info,
                onTap: () => onOpenTab(1),
              ),
              Divider(color: AppTheme.border.withValues(alpha: 0.6)),
              _ActionRow(
                icon: Icons.history_rounded,
                title: 'Request history',
                subtitle: 'Filter all requests and remove records',
                iconBg: AppTheme.adminLight,
                iconColor: AppTheme.adminPrimary,
                onTap: () => onOpenTab(2),
              ),
              Divider(color: AppTheme.border.withValues(alpha: 0.6)),
              _ActionRow(
                icon: Icons.priority_high_rounded,
                title: 'Emergency requests',
                subtitle: 'Focus only on urgent blood requests',
                iconBg: AppTheme.warningBg,
                iconColor: AppTheme.warning,
                onTap: () => onOpenTab(3),
              ),
            ],
          ),
        ),

        // ── Error banner ─────────────────────────
        if (admin.error != null) ...[
          const SizedBox(height: 16),
          AppCard(
            color: AppTheme.warningBg,
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    admin.error!,
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.warning),
                  onPressed: () => context.read<AdminProvider>().clearError(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppTheme.textMuted),
        ],
      ),
      ),
    );
  }
}
