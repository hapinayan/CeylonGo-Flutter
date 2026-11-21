import 'package:flutter/material.dart';

/// Stock and availability badge for handcrafted artisan products.
class StockBadge extends StatelessWidget {
  final int stockQuantity;
  final bool isAvailable;
  final bool isActive;
  final String approvalStatus;

  const StockBadge({
    super.key,
    required this.stockQuantity,
    this.isAvailable = true,
    this.isActive = true,
    this.approvalStatus = 'approved',
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive || approvalStatus != 'approved' || !isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Unavailable',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    if (stockQuantity <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF991B1B),
          ),
        ),
      );
    }

    if (stockQuantity <= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Text(
          'Only $stockQuantity left',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF92400E),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Text(
        '$stockQuantity In Stock',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF166534),
        ),
      ),
    );
  }
}

