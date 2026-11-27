import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/vendor_models.dart';
import '../services/vendor_demo_service.dart';
import '../widgets/vendor_bottom_nav_bar.dart';

/// Vendor Booking Management Screen (Simulated Demo State)
/// Supports All, Pending, Accepted, Rejected, Completed filters,
/// search, booking details, and simulated status transitions.
class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  final VendorDemoService _service = VendorDemoService.instance;
  final TextEditingController _searchController = TextEditingController();
  VendorBookingStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VendorBookingRequest> get _filteredBookings {
    final q = _searchController.text.trim().toLowerCase();
    return _service.bookings.where((b) {
      if (_statusFilter != null && b.status != _statusFilter) return false;
      if (q.isNotEmpty &&
          !b.listingTitle.toLowerCase().contains(q) &&
          !b.customerName.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _updateStatus(VendorBookingRequest booking, VendorBookingStatus status) {
    _service.updateBookingStatus(booking.id, status);
    setState(() {});
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulated demo status updated to ${status.label} (no real booking confirmation sent).',
        ),
        backgroundColor: AppTheme.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBookingDetails(VendorBookingRequest b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.listingTitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text('Customer: ${b.customerName}'),
            Text('Email: ${b.customerEmail}'),
            Text('Phone: ${b.customerPhone}'),
            Text('Dates: ${b.dateRange} (${b.unitsLabel})'),
            Text('Total: LKR ${b.totalLkr}'),
            const SizedBox(height: 6),
            Text('Notes: ${b.notes}'),
            const SizedBox(height: 12),
            const Text(
              'Demo mode: status changes are simulated locally.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A4DF5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredBookings;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const VendorBottomNavigationBar(currentIndex: 2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Booking Management',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Text(
                'Simulated Demo Mode: booking actions update local state only.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: TextField(
              key: const Key('vendor_bookings_search'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search customer or listing...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryNavy,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFDBEAFE)),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                ),
                ...VendorBookingStatus.values.map(
                  (st) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(st.label),
                      selected: _statusFilter == st,
                      onSelected: (_) => setState(() => _statusFilter = st),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No booking requests found.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final b = items[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    b.listingTitle,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    b.status.label,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A4DF5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${b.customerName} • ${b.dateRange} • ${b.unitsLabel}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LKR ${b.totalLkr}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A4DF5),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _showBookingDetails(b),
                                  child: const Text('Details'),
                                ),
                                if (b.status == VendorBookingStatus.pending) ...[
                                  ElevatedButton(
                                    key: Key('accept_booking_${b.id}'),
                                    onPressed: () => _updateStatus(
                                      b,
                                      VendorBookingStatus.accepted,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                  OutlinedButton(
                                    key: Key('reject_booking_${b.id}'),
                                    onPressed: () => _updateStatus(
                                      b,
                                      VendorBookingStatus.rejected,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.errorRed,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ],
                                if (b.status ==
                                    VendorBookingStatus.accepted) ...[
                                  ElevatedButton(
                                    key: Key('complete_booking_${b.id}'),
                                    onPressed: () => _updateStatus(
                                      b,
                                      VendorBookingStatus.completed,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0A4DF5),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Mark Completed'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

