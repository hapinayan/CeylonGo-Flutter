import 'package:flutter/material.dart';

import '../models/artisan_reservation_model.dart';

/// Pill badge displaying the lifecycle status of an artisan reservation.
/// Supported statuses: pending, confirmed, ready_for_pickup, completed, cancelled, expired.
/// (Explicitly rejects 'rejected' status).
class ReservationStatusBadge extends StatelessWidget {
  final ReservationStatus status;
  final bool isCompact;

  const ReservationStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.color.withAlpha(70),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: isCompact ? 12 : 14,
            color: status.color,
          ),
          SizedBox(width: isCompact ? 3 : 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

