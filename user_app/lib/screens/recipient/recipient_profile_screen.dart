import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/app_theme.dart';

class RecipientProfileScreen extends StatelessWidget {
  const RecipientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final requests =
        context.watch<RequestProvider>().recipientRequests;
    if (user == null) return const SizedBox.shrink();

    final pending = requests.where((r) => r.isPending).length;
    final accepted = requests.where((r) => r.isAccepted).length;
    final completed = requests.where((r) => r.isCompleted).length;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Profile card ───────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.local_hospital_rounded,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Recipient',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Stats ──────────────────────────
            Row(
              children: [
                Expanded(
                    child: _Stat(
                        label: 'Total',
                        value: '${requests.length}',
                        color: AppTheme.primary)),
                const SizedBox(width: 8),
                Expanded(
                    child: _Stat(
                        label: 'Pending',
                        value: '$pending',
                        color: AppTheme.warning)),
                const SizedBox(width: 8),
                Expanded(
                    child: _Stat(
                        label: 'Accepted',
                        value: '$accepted',
                        color: AppTheme.success)),
                const SizedBox(width: 8),
                Expanded(
                    child: _Stat(
                        label: 'Done',
                        value: '$completed',
                        color: AppTheme.info)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Settings tiles ─────────────────
            _Tile(
              icon: Icons.email_outlined,
              title: 'Email address',
              subtitle: user.email,
            ),
            const SizedBox(height: 8),
            const _NotificationTile(),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.info_outline_rounded,
              title: 'About Blood Connect',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // ── Logout ─────────────────────────
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
                        onPressed: () =>
                            Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, true),
                        child: const Text('Log out',
                            style: TextStyle(
                                color: AppTheme.primary)),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AppAuthProvider>().logout();
                }
              },
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.primary),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Stat tile ──────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings tile ──────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: auth.isLoading ? null : (value) => _toggle(context, value),
        activeThumbColor: AppTheme.primary,
        secondary: Container(
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
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: const Text(
          'Request updates and alerts',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}
