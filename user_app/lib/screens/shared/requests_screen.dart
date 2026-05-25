import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/request_card.dart';

class RequestsScreen extends StatefulWidget {
  final bool isForDonor;
  const RequestsScreen({super.key, required this.isForDonor});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isForDonor ? 3 : 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<RequestModel> _filter(List<RequestModel> all, String status) {
    if (status == 'all') return all;
    return all.where((r) => r.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user;
    final rp = context.watch<RequestProvider>();
    if (user == null) return const SizedBox.shrink();

    final all = widget.isForDonor
        ? rp.donorRequests
        : rp.recipientRequests;

    final tabs = widget.isForDonor
        ? ['All', 'Pending', 'Responded']
        : ['All', 'Pending', 'Accepted', 'History'];

    final views = widget.isForDonor
        ? [
            _RequestList(requests: all, isDonorView: true),
            _RequestList(requests: _filter(all, 'pending'), isDonorView: true),
            _RequestList(
              requests:
                  all.where((r) => r.isAccepted || r.isRejected).toList(),
              isDonorView: true,
            ),
          ]
        : [
            _RequestList(requests: all, isDonorView: false),
            _RequestList(
                requests: _filter(all, 'pending'), isDonorView: false),
            _RequestList(
                requests: _filter(all, 'accepted'), isDonorView: false),
            _RequestList(
              requests: all
                  .where((r) => r.isRejected || r.isCompleted)
                  .toList(),
              isDonorView: false,
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isForDonor ? 'Incoming Requests' : 'My Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: tabs.length > 3,
          tabAlignment:
              tabs.length > 3 ? TabAlignment.start : TabAlignment.fill,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: views,
      ),
    );
  }
}

// ── Request list ───────────────────────────────

class _RequestList extends StatelessWidget {
  final List<RequestModel> requests;
  final bool isDonorView;

  const _RequestList({
    required this.requests,
    required this.isDonorView,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Nothing here',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = requests[index];
        return RequestCard(
          request: req,
          isDonorView: isDonorView,
          onAccept: isDonorView && req.isPending
              ? () => _handleAccept(context, req)
              : null,
          onReject: isDonorView && req.isPending
              ? () => _handleReject(context, req)
              : null,
          onComplete: !isDonorView && req.isAccepted
              ? () => _handleComplete(context, req)
              : null,
        );
      },
    );
  }

  Future<void> _handleAccept(BuildContext context, RequestModel req) async {
    final ok =
        await context.read<RequestProvider>().acceptRequest(req.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✓  Request accepted!' : 'Failed to accept'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  Future<void> _handleReject(BuildContext context, RequestModel req) async {
    final ok =
        await context.read<RequestProvider>().rejectRequest(req.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Request rejected' : 'Failed to reject'),
      ),
    );
  }

  Future<void> _handleComplete(
      BuildContext context, RequestModel req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as completed'),
        content:
            const Text('Confirm that the blood donation was completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final ok = await context
        .read<RequestProvider>()
        .completeRequest(req.id, req.donorId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '✓  Donation marked as completed. Thank you!'
            : 'Failed to update'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}
