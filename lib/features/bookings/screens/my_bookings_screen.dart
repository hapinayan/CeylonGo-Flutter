import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../../categories/models/discovery_models.dart';
import '../models/booking_models.dart';
import '../services/booking_payment_service.dart';
import '../widgets/booking_payment_sheet.dart';

/// Academic MVP Traveler My Bookings Screen (GET /api/v1/bookings/my).
class MyBookingsScreen extends StatefulWidget {
  final BookingPaymentService? service;

  const MyBookingsScreen({super.key, this.service});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late final BookingPaymentService _service;

  bool _isLoading = true;
  String? _error;
  List<BookingRecord> _bookings = [];
  String? _selectedCategory; // null = All, 'homestay', 'activity', 'tour_guide', 'rental'
  int? _busyBookingId;

  static const _categories = <(String?, String)>[
    (null, 'All'),
    ('homestay', 'Homestays'),
    ('activity', 'Activities'),
    ('tour_guide', 'Guides'),
    ('rental', 'Rentals'),
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? BookingPaymentService();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _service.getMyBookings(category: _selectedCategory);
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load bookings. Please try again.';
      });
    }
  }

  Future<void> _openBookingDetail(BookingRecord item) async {
    BookingRecord full = item;
    try {
      full = await _service.getBookingDetails(item.id);
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final payment = full.latestPayment;
        final canPay =
            full.status != 'cancelled' &&
            full.status != 'rejected' &&
            full.status != 'completed' &&
            !full.hasAcceptedPaymentMethod;
        final canCancel = full.status == 'pending' || full.status == 'confirmed';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      full.bookingReference ?? 'Booking #${full.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  _StatusBadge(status: full.status),
                ],
              ),
              const SizedBox(height: 14),
              _DetailRow(label: 'Listing ID', value: '#${full.listingId}'),
              _DetailRow(
                label: 'Dates',
                value:
                    '${_formatDate(full.startsAt)}  ->  ${_formatDate(full.endsAt)}',
              ),
              _DetailRow(label: 'Quantity / Guests', value: '${full.quantity}'),
              _DetailRow(
                label: 'Total Amount',
                value: formatLkrAmount(full.totalAmount),
              ),
              _DetailRow(
                label: 'Payment Status',
                value: payment != null
                    ? payment.readableLabel
                    : 'Not selected yet',
              ),
              if (full.payments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Payment Attempts (${full.payments.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                ...full.payments.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Attempt #${p.attemptNo}: ${p.readableLabel} (${formatLkrAmount(p.displayAmount)})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (canPay)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPaymentScreen(
                          booking: full,
                          serviceTitle:
                              full.bookingReference ?? 'Booking #${full.id}',
                          summarySubtitle:
                              '${_formatDate(full.startsAt)} - ${_formatDate(full.endsAt)}',
                          service: _service,
                        ),
                      ),
                    );
                    _loadBookings();
                  },
                  icon: const Icon(Icons.payment_outlined, size: 18),
                  label: Text(
                    payment == null ? 'Select Payment Method' : 'Retry Payment',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (canCancel) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busyBookingId == full.id
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _cancelBooking(full);
                        },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelBooking(BookingRecord booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Cancel ${booking.bookingReference ?? 'Booking #${booking.id}'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busyBookingId = booking.id);
    try {
      await _service.updateBookingStatus(
        booking.id,
        toStatus: 'cancelled',
        reason: 'Cancelled by traveler',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
      await _loadBookings();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel booking.')),
      );
    } finally {
      if (mounted) setState(() => _busyBookingId = null);
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Bookings'),
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
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.$2),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat.$1);
                        _loadBookings();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy_outlined,
                                size: 46,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _loadBookings,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _bookings.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.luggage_outlined,
                                    size: 52,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No bookings yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Your homestay, activity, tour guide, and rental bookings will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: _bookings.length,
                              itemBuilder: (_, index) {
                                final item = _bookings[index];
                                final payment = item.latestPayment;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: AppTheme.borderSlate,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _openBookingDetail(item),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.bookingReference ??
                                                      'Booking #${item.id}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryNavy,
                                                  ),
                                                ),
                                              ),
                                              _StatusBadge(status: item.status),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_formatDate(item.startsAt)}  ->  ${_formatDate(item.endsAt)}   •   Qty: ${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                formatLkrAmount(item.totalAmount),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryNavy,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                payment?.readableLabel ??
                                                    'Payment pending',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: payment?.status ==
                                                          'demo_failed'
                                                      ? AppTheme.errorRed
                                                      : AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        bg = AppTheme.successGreen.withOpacity(0.12);
        fg = AppTheme.successGreen;
        break;
      case 'rejected':
      case 'cancelled':
        bg = AppTheme.errorRed.withOpacity(0.12);
        fg = AppTheme.errorRed;
        break;
      default:
        bg = AppTheme.accentOrange.withOpacity(0.15);
        fg = AppTheme.accentHover;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
