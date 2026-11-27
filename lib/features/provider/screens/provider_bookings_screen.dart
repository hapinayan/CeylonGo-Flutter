import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../../bookings/models/booking_models.dart';
import '../../categories/models/discovery_models.dart';
import '../services/provider_service.dart';

/// Provider Bookings Management Screen (`/api/v1/provider/bookings`)
class ProviderBookingsScreen extends StatefulWidget {
  final ProviderService? providerService;
  final String? initialStatus;

  const ProviderBookingsScreen({
    super.key,
    this.providerService,
    this.initialStatus,
  });

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  late final ProviderService _service;
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  List<BookingRecord> _bookings = [];

  static const _statuses = <(String?, String)>[
    (null, 'All'),
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('completed', 'Completed'),
    ('rejected', 'Rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.providerService ?? ProviderService();
    _statusFilter = widget.initialStatus;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getProviderBookings(status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load bookings.';
      });
    }
  }

  Future<void> _openDetail(BookingRecord item) async {
    BookingRecord full = item;
    try {
      full = await _service.getProviderBookingDetails(item.id);
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              full.bookingReference ?? 'Booking #${full.id}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text('Status: ${full.status.toUpperCase()}'),
            Text('Total: ${formatLkrAmount(full.totalAmount)} • Qty: ${full.quantity}'),
            if (full.travelerContact != null) ...[
              const SizedBox(height: 8),
              Text(
                'Traveler: ${full.travelerContact!.fullName}\n'
                'Email: ${full.travelerContact!.email}'
                '${full.travelerContact!.phone != null ? '\nPhone: ${full.travelerContact!.phone}' : ''}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
            if (full.latestPayment != null) ...[
              const SizedBox(height: 8),
              Text('Payment: ${full.latestPayment!.readableLabel}'),
            ],
            const SizedBox(height: 16),
            if (full.status == 'pending') ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _updateStatus(full.id, 'confirmed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept & Confirm Booking'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _rejectWithReason(full.id);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                ),
                child: const Text('Reject Booking'),
              ),
            ] else if (full.status == 'confirmed')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _updateStatus(full.id, 'completed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark Completed'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectWithReason(int bookingId) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _updateStatus(bookingId, 'rejected', reason: reasonCtrl.text);
    }
  }

  Future<void> _updateStatus(
    int bookingId,
    String toStatus, {
    String? reason,
  }) async {
    try {
      await _service.updateBookingStatus(
        bookingId,
        toStatus: toStatus,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking marked $toStatus.')),
      );
      _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Provider Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.$2),
                      selected: _statusFilter == s.$1,
                      onSelected: (_) {
                        setState(() => _statusFilter = s.$1);
                        _load();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _bookings.isEmpty
                        ? const Center(
                            child: Text(
                              'No bookings match this filter.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: _bookings.length,
                              itemBuilder: (_, index) {
                                final b = _bookings[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    onTap: () => _openDetail(b),
                                    title: Text(
                                      b.bookingReference ?? 'Booking #${b.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Listing #${b.listingId} • Qty: ${b.quantity} • ${formatLkrAmount(b.totalAmount)}',
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        b.status.toUpperCase(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
