import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/vendor_models.dart';
import '../services/vendor_demo_service.dart';

/// Vendor Earnings & Payments Screen (Simulated Demo Data Only)
/// Displays demo totals, pending/completed amounts, date/status filters,
/// and booking-linked transaction history in LKR.
class VendorEarningsScreen extends StatefulWidget {
  const VendorEarningsScreen({super.key});

  @override
  State<VendorEarningsScreen> createState() => _VendorEarningsScreenState();
}

class _VendorEarningsScreenState extends State<VendorEarningsScreen> {
  final VendorDemoService _service = VendorDemoService.instance;
  String _dateFilter = 'All'; // All | Dec 2026 | Completed | Pending

  String _formatLkr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'LKR ${buf.toString()}';
  }

  List<VendorBookingRequest> get _relevantBookings {
    final vendorListingTitles = _service.listings.map((l) => l.title).toSet();
    final scoped = _service.bookings
        .where((b) => vendorListingTitles.contains(b.listingTitle))
        .toList();
    return scoped;
  }

  List<VendorBookingRequest> get _filteredTransactions {
    return _relevantBookings.where((b) {
      if (b.status == VendorBookingStatus.rejected) return false;
      switch (_dateFilter) {
        case 'Dec 2026':
          return b.dateRange.contains('Dec');
        case 'Completed':
          return b.status == VendorBookingStatus.completed;
        case 'Pending':
          return b.status == VendorBookingStatus.pending ||
              b.status == VendorBookingStatus.accepted;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = _relevantBookings;
    final completedTotal = all
        .where((b) => b.status == VendorBookingStatus.completed)
        .fold<int>(0, (sum, b) => sum + b.totalLkr);
    final pendingTotal = all
        .where(
          (b) =>
              b.status == VendorBookingStatus.pending ||
              b.status == VendorBookingStatus.accepted,
        )
        .fold<int>(0, (sum, b) => sum + b.totalLkr);
    final totalEarnings = completedTotal + pendingTotal;
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Earnings & Payments',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const Key('earnings_demo_banner'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Demo Data Only: Simulated LKR figures from local bookings. No real bank transfers or payment processing occur.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SummaryCard(
                label: 'Total Earnings (Simulated Demo)',
                amount: _formatLkr(totalEarnings),
                accentColor: const Color(0xFF0A4DF5),
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Pending Payments (Demo)',
                      amount: _formatLkr(pendingTotal),
                      accentColor: const Color(0xFFEA580C),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Completed Payments (Demo)',
                      amount: _formatLkr(completedTotal),
                      accentColor: const Color(0xFF16A34A),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Transaction History (Demo)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Dec 2026', 'Completed', 'Pending']
                      .map((filter) {
                    final isSelected = _dateFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('earnings_filter_$filter'),
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0A4DF5),
                        backgroundColor: const Color(0xFFF8FAFC),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryNavy,
                        ),
                        onSelected: (_) =>
                            setState(() => _dateFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'No simulated transactions match this filter.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
              else
                ...transactions.map((b) {
                  final isCompleted =
                      b.status == VendorBookingStatus.completed;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.listingTitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${b.customerName} • ${b.dateRange}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCompleted
                                    ? 'Simulated Completed'
                                    : 'Simulated Pending',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatLkr(b.totalLkr),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A4DF5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color accentColor;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

