import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_card.dart';
import 'admin_history_screen.dart';

class AdminEmergencyScreen extends StatelessWidget {
  const AdminEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyRequests = context
        .watch<AdminProvider>()
        .requests
        .where((request) => request.isEmergency)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppCard(
            color: AppTheme.warningBg,
            boxShadow: const [],
            child: Row(
              children: [
                const Icon(
                  Icons.priority_high_rounded,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${emergencyRequests.length} emergency request${emergencyRequests.length == 1 ? '' : 's'} need attention',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: emergencyRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No emergency requests right now',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: emergencyRequests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      AdminRequestTile(request: emergencyRequests[index]),
                ),
        ),
      ],
    );
  }
}
