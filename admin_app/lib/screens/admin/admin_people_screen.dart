import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_card.dart';

class AdminPeopleScreen extends StatefulWidget {
  const AdminPeopleScreen({super.key});

  @override
  State<AdminPeopleScreen> createState() => _AdminPeopleScreenState();
}

class _AdminPeopleScreenState extends State<AdminPeopleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _roleFilter = 'all';
  String _bloodFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      children: [
        Material(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Users (${admin.users.where((u) => !u.isAdmin).length})'),
              Tab(text: 'Donors (${admin.donors.length})'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search people',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _roleFilter,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All roles')),
                        DropdownMenuItem(value: 'donor', child: Text('Donors')),
                        DropdownMenuItem(value: 'recipient', child: Text('Recipients')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                      ],
                      onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _bloodFilter,
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
                      onChanged: (v) => setState(() => _bloodFilter = v ?? 'all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _UserList(
                users: admin.users,
                query: _query,
                roleFilter: _roleFilter,
                bloodFilter: _bloodFilter,
              ),
              _DonorList(
                donors: admin.donors,
                query: _query,
                roleFilter: _roleFilter,
                bloodFilter: _bloodFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── User List ──────────────────────────────────

class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final String query;
  final String roleFilter;
  final String bloodFilter;

  const _UserList({
    required this.users,
    required this.query,
    required this.roleFilter,
    required this.bloodFilter,
  });

  @override
  Widget build(BuildContext context) {
    final visible = users.where((u) {
      if (u.isAdmin) return false;
      if (roleFilter == 'suspended' && !u.isSuspended) return false;
      if (roleFilter != 'all' &&
          roleFilter != 'suspended' &&
          u.role != roleFilter) {
        return false;
      }
      if (bloodFilter != 'all' && u.bloodGroup != bloodFilter) return false;
      if (query.isEmpty) return true;
      final haystack = '${u.fullName} ${u.email} ${u.city ?? ''} ${u.role}'
          .toLowerCase();
      return haystack.contains(query);
    }).toList();
    if (visible.isEmpty) {
      return const _EmptyAdminList(message: 'No users registered yet');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _UserTile(user: visible[index]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  Future<void> _confirmDelete(BuildContext context) async {
    final currentUid = context.read<AppAuthProvider>().user?.uid;

    // Self-delete guard (UI layer)
    if (user.uid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'Remove ${user.fullName} and all their requests & donor data.\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final success = await context
          .read<AdminProvider>()
          .deleteUser(user.uid, currentAdminUid: currentUid);
      if (context.mounted) {
        final errorMsg = context.read<AdminProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '${user.fullName} removed successfully'
                : (errorMsg ?? 'Delete failed')),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoleBadge(role: user.role),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Joined ${DateFormat.yMMMd().format(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: user.isSuspended ? 'Reactivate account' : 'Suspend account',
            onPressed: () => _toggleSuspended(context),
            icon: Icon(
              user.isSuspended
                  ? Icons.lock_open_outlined
                  : Icons.block_outlined,
              color: user.isSuspended ? AppTheme.success : AppTheme.warning,
            ),
          ),
          IconButton(
            tooltip: 'Delete user',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSuspended(BuildContext context) async {
    final suspend = !user.isSuspended;
    final success = await context
        .read<AdminProvider>()
        .setAccountSuspended(user.uid, suspend);
    if (!context.mounted) return;
    final errorMsg = context.read<AdminProvider>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (suspend ? 'Account suspended' : 'Account reactivated')
            : (errorMsg ?? 'Update failed')),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}

// ── Donor List ─────────────────────────────────

class _DonorList extends StatelessWidget {
  final List<DonorModel> donors;
  final String query;
  final String roleFilter;
  final String bloodFilter;

  const _DonorList({
    required this.donors,
    required this.query,
    required this.roleFilter,
    required this.bloodFilter,
  });

  @override
  Widget build(BuildContext context) {
    final visible = donors.where((d) {
      if (roleFilter == 'recipient') return false;
      if (roleFilter == 'suspended' && !d.isSuspended) return false;
      if (bloodFilter != 'all' && d.bloodGroup != bloodFilter) return false;
      if (query.isEmpty) return true;
      final haystack = '${d.fullName} ${d.email} ${d.city} ${d.bloodGroup}'
          .toLowerCase();
      return haystack.contains(query);
    }).toList();

    if (visible.isEmpty) {
      return const _EmptyAdminList(message: 'No donor profiles yet');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _DonorTile(donor: visible[index]),
    );
  }
}

class _DonorTile extends StatelessWidget {
  final DonorModel donor;
  const _DonorTile({required this.donor});

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete donor profile?'),
        content: Text(
          'Remove ${donor.fullName}\'s donor profile and their request history as a donor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final success = await context.read<AdminProvider>().deleteDonor(donor.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Donor profile removed' : 'Delete failed',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              donor.bloodGroup,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donor.fullName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${donor.city} · ${donor.age}y · ${donor.healthStatus}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: donor.isAvailable
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      donor.isAvailable ? 'Available' : 'Not available',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: donor.isAvailable
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: donor.isSuspended ? 'Reactivate account' : 'Suspend account',
            onPressed: () => _toggleSuspended(context),
            icon: Icon(
              donor.isSuspended
                  ? Icons.lock_open_outlined
                  : Icons.block_outlined,
              color: donor.isSuspended ? AppTheme.success : AppTheme.warning,
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSuspended(BuildContext context) async {
    final suspend = !donor.isSuspended;
    final success = await context
        .read<AdminProvider>()
        .setAccountSuspended(donor.uid, suspend);
    if (!context.mounted) return;
    final errorMsg = context.read<AdminProvider>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (suspend ? 'Account suspended' : 'Account reactivated')
            : (errorMsg ?? 'Update failed')),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}

// ── Empty State ────────────────────────────────

class _EmptyAdminList extends StatelessWidget {
  final String message;
  const _EmptyAdminList({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
