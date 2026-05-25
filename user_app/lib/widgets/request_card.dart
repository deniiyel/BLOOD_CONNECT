import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final bool isDonorView;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const RequestCard({
    super.key,
    required this.request,
    required this.isDonorView,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.onTap,
  });

  Color get _statusColor => switch (request.status) {
        'pending' => AppTheme.warning,
        'accepted' => AppTheme.success,
        'rejected' => AppTheme.error,
        'completed' => AppTheme.info,
        'expired' => AppTheme.textMuted,
        _ => AppTheme.textMuted,
      };

  IconData get _statusIcon => switch (request.status) {
        'pending' => Icons.schedule_rounded,
        'accepted' => Icons.check_circle_outline,
        'rejected' => Icons.cancel_outlined,
        'completed' => Icons.done_all_rounded,
        'expired' => Icons.timer_off_outlined,
        _ => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: request.isEmergency
                ? AppTheme.warning.withValues(alpha: 0.5)
                : (isDark ? AppTheme.darkBorder : AppTheme.border),
            width: request.isEmergency ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  // Blood group circle
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        request.bloodGroup,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDonorView
                              ? 'From: ${request.recipientName}'
                              : 'Patient: ${request.patientName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y • h:mm a')
                              .format(request.createdAt),
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Chip(
                        label: request.statusLabel,
                        color: _statusColor,
                        icon: _statusIcon,
                      ),
                      if (request.isEmergency) ...[
                        const SizedBox(height: 4),
                        _Chip(
                          label: 'EMERGENCY',
                          color: AppTheme.warning,
                          icon: Icons.emergency_rounded,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.local_hospital_outlined,
                    text: request.hospital,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: request.city,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: request.recipientContact,
                  ),
                  if (request.additionalNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      text: request.additionalNotes!,
                    ),
                  ],
                  if (request.unitsNeeded > 1) ...[
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.water_drop_outlined,
                      text: '${request.unitsNeeded} units needed',
                    ),
                  ],
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: request.isExpired
                        ? Icons.timer_off_outlined
                        : Icons.timer_outlined,
                    text: request.isExpired
                        ? 'Request expired'
                        : 'Expires ${DateFormat('MMM d, h:mm a').format(request.expiresAt)}',
                  ),
                ],
              ),
            ),

            // ── Donor view: accept / reject ──────
            if (isDonorView &&
                request.canRespond &&
                (onAccept != null || onReject != null))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(
                              color: AppTheme.error.withValues(alpha: 0.5)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Recipient view: mark complete ────
            if (!isDonorView &&
                request.isAccepted &&
                onComplete != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark as completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.info,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Chip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
