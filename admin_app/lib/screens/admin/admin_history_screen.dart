import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/blood_group_badge.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';
  String _bloodFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<AdminProvider>().requests.where((request) {
      if (_statusFilter != 'all' &&
          request.status.trim().toLowerCase() != _statusFilter) {
        return false;
      }
      if (_bloodFilter != 'all' && request.bloodGroup != _bloodFilter) {
        return false;
      }
      if (_query.isEmpty) return true;
      final haystack =
          '${request.patientName} ${request.recipientName} ${request.donorName} ${request.hospital} ${request.city}'
              .toLowerCase();
      return haystack.contains(_query);
    }).toList();

    if (requests.isEmpty) {
      return Column(
        children: [
          _RequestFilters(
            searchCtrl: _searchCtrl,
            statusFilter: _statusFilter,
            bloodFilter: _bloodFilter,
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            onBloodChanged: (v) => setState(() => _bloodFilter = v),
          ),
          Expanded(
            child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No request history yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _RequestFilters(
          searchCtrl: _searchCtrl,
          statusFilter: _statusFilter,
          bloodFilter: _bloodFilter,
          onStatusChanged: (v) => setState(() => _statusFilter = v),
          onBloodChanged: (v) => setState(() => _bloodFilter = v),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                AdminRequestTile(request: requests[index]),
          ),
        ),
      ],
    );
  }
}

class AdminRequestTile extends StatelessWidget {
  final RequestModel request;
  const AdminRequestTile({super.key, required this.request});

  Color get _statusColor => switch (request.status) {
        'pending' => AppTheme.warning,
        'accepted' => AppTheme.success,
        'rejected' => AppTheme.error,
        'completed' => AppTheme.info,
        _ => AppTheme.textMuted,
      };

  Future<void> _showActions(BuildContext context) async {
    // Capture the admin uid before the async gap
    final currentAdminUid = context.read<AppAuthProvider>().user?.uid;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Manage record',
                  style: Theme.of(sheetCtx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                _SheetAction(
                  icon: Icons.delete_outline,
                  iconColor: AppTheme.error,
                  title: 'Delete this request',
                  subtitle: 'Remove from history permanently',
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final ok = await _confirm(
                      context,
                      'Delete request?',
                      'Remove this request from history.',
                    );
                    if (ok && context.mounted) {
                      final success = await context
                          .read<AdminProvider>()
                          .deleteRequest(request.id);
                      if (context.mounted) {
                        _showSnack(context, success, 'Request deleted', 'Delete failed');
                      }
                    }
                  },
                ),

                _SheetAction(
                  icon: Icons.person_off_outlined,
                  iconColor: AppTheme.warning,
                  title: 'Delete recipient (${request.recipientName})',
                  subtitle: 'User account + all their data',
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final ok = await _confirm(
                      context,
                      'Delete recipient?',
                      'Removes ${request.recipientName} and all linked records.',
                    );
                    if (ok && context.mounted) {
                      final success = await context
                          .read<AdminProvider>()
                          .deleteUser(request.recipientId,
                              currentAdminUid: currentAdminUid);
                      if (context.mounted) {
                        final errMsg = context.read<AdminProvider>().error;
                        _showSnack(
                          context,
                          success,
                          'Recipient removed',
                          errMsg ?? 'Delete failed',
                        );
                      }
                    }
                  },
                ),

                _SheetAction(
                  icon: Icons.bloodtype_outlined,
                  iconColor: AppTheme.primary,
                  title: 'Delete donor (${request.donorName})',
                  subtitle: 'Donor profile + requests as donor',
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final ok = await _confirm(
                      context,
                      'Delete donor profile?',
                      'Removes ${request.donorName}\'s donor data.',
                    );
                    if (ok && context.mounted) {
                      final success = await context
                          .read<AdminProvider>()
                          .deleteDonor(request.donorId);
                      if (context.mounted) {
                        _showSnack(context, success, 'Donor removed', 'Delete failed');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String body,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(
    BuildContext context,
    bool success,
    String successMsg,
    String failMsg,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successMsg : failMsg),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _showActions(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BloodGroupBadge(bloodGroup: request.bloodGroup, isSmall: true),
              const SizedBox(width: 8),
              if (request.isEmergency)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'EMERGENCY',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.patientName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          _InfoRow(Icons.local_hospital_outlined, request.hospital),
          _InfoRow(Icons.location_on_outlined, request.city),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PartyChip(label: 'Recipient', name: request.recipientName),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PartyChip(label: 'Donor', name: request.donorName),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateHelpers.formatFull(request.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to manage',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.adminPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _RequestFilters extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String statusFilter;
  final String bloodFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onBloodChanged;

  const _RequestFilters({
    required this.searchCtrl,
    required this.statusFilter,
    required this.bloodFilter,
    required this.onStatusChanged,
    required this.onBloodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search requests',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: statusFilter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (v) => onStatusChanged(v ?? 'all'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: bloodFilter,
                  decoration: const InputDecoration(labelText: 'Blood'),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All groups')),
                    ...AppConstants.bloodGroups.map(
                      (group) => DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      ),
                    ),
                  ],
                  onChanged: (v) => onBloodChanged(v ?? 'all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyChip extends StatelessWidget {
  final String label;
  final String name;
  const _PartyChip({required this.label, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
