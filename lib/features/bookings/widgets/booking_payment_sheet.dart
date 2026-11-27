import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../auth/models/api_error.dart';
import '../models/booking_models.dart';
import '../services/booking_payment_service.dart';

/// Academic MVP Booking Payment Selection Screen
/// Supports Simulated Online Payment (success & failure) and Pay at Location
/// with canonical UUID v4 request_key preservation across retries.
class BookingPaymentScreen extends StatefulWidget {
  final BookingRecord booking;
  final String serviceTitle;
  final String summarySubtitle;
  final BookingPaymentService? service;

  const BookingPaymentScreen({
    super.key,
    required this.booking,
    required this.serviceTitle,
    required this.summarySubtitle,
    this.service,
  });

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  late final BookingPaymentService _service;
  late BookingRecord _booking;

  // Idempotency state: preserve exact request_key + attempt_no across retries
  // for the same payment intent; generate a new key only for a new intent/attempt.
  String? _pendingRequestKey;
  String? _pendingMethod; // 'simulated_success' | 'simulated_failure' | 'at_location'
  int? _pendingAttemptNo;

  bool _isSubmitting = false;
  String? _errorMessage;
  PaymentRecord? _lastResult;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? BookingPaymentService();
    _booking = widget.booking;
    _lastResult = _booking.latestPayment;
  }

  Future<void> _refreshBooking() async {
    try {
      final updated = await _service.getBookingDetails(_booking.id);
      if (mounted) {
        setState(() {
          _booking = updated;
          _lastResult = updated.latestPayment;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitPayment(String intent) async {
    if (_isSubmitting) return;

    // If the user is retrying the exact same failed network call, reuse the
    // existing request_key and attempt_no. Otherwise create a fresh canonical UUID v4.
    if (_pendingMethod != intent || _pendingRequestKey == null) {
      _pendingMethod = intent;
      _pendingRequestKey = UuidGenerator.v4();
      _pendingAttemptNo = _booking.nextPaymentAttemptNo;
    }

    final requestKey = _pendingRequestKey!;
    final attemptNo = _pendingAttemptNo ?? _booking.nextPaymentAttemptNo;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      PaymentRecord result;
      if (intent == 'at_location') {
        result = await _service.processAtLocationPayment(
          bookingId: _booking.id,
          requestKey: requestKey,
        );
      } else {
        final outcome = intent == 'simulated_success' ? 'success' : 'failure';
        result = await _service.processSimulatedPayment(
          bookingId: _booking.id,
          requestKey: requestKey,
          attemptNo: attemptNo,
          simulateOutcome: outcome,
        );
      }

      // Server responded and recorded this payment attempt -> clear pending retry key
      _pendingMethod = null;
      _pendingRequestKey = null;
      _pendingAttemptNo = null;

      await _refreshBooking();

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _lastResult = result;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      // If non-network validation/conflict (4xx), reset key so next attempt gets fresh key
      if (e.statusCode >= 400 && e.statusCode < 500) {
        _pendingMethod = null;
        _pendingRequestKey = null;
        _pendingAttemptNo = null;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Unable to reach server. Tap the same option to retry safely without duplicate charges.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResolvedOption = _booking.hasAcceptedPaymentMethod;
    final latest = _lastResult;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Select Payment Option'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Booking Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.serviceTitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _booking.status.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A4DF5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.summarySubtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ref: ${_booking.bookingReference ?? '#${_booking.id}'}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        '${_booking.currency} ${_booking.totalAmount}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Academic MVP Simulated Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Academic MVP Payment Notice: Online payment is a simulated demonstration (no real money or card data). Bookings remain Pending until accepted by the service provider.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('payment_error_banner'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorRed.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (latest != null) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('payment_status_card'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: latest.status == 'demo_failed'
                      ? AppTheme.errorRed.withAlpha(18)
                      : AppTheme.successGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: latest.status == 'demo_failed'
                        ? AppTheme.errorRed.withAlpha(90)
                        : AppTheme.successGreen.withAlpha(90),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          latest.status == 'demo_failed'
                              ? Icons.cancel_outlined
                              : Icons.check_circle_outline,
                          color: latest.status == 'demo_failed'
                              ? AppTheme.errorRed
                              : AppTheme.successGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            latest.readableLabel,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: latest.status == 'demo_failed'
                                  ? AppTheme.errorRed
                                  : AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      latest.status == 'demo_failed'
                          ? 'Attempt #${latest.attemptNo} failed. Your booking remains Pending — you can retry Simulated Payment or choose Pay at Location.'
                          : 'Payment choice recorded (Attempt #${latest.attemptNo}). The provider can now review and confirm your booking.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            if (!hasResolvedOption && _booking.status == 'pending') ...[
              // Option 1: Simulated Online Payment
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.credit_card_outlined, color: Color(0xFF0A4DF5)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Simulated Online Payment (Demo)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Test either a successful or failed online payment outcome for demonstration.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            key: const Key('simulate_payment_success_btn'),
                            onPressed: _isSubmitting
                                ? null
                                : () => _submitPayment('simulated_success'),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Simulate Success'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A4DF5),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('simulate_payment_failure_btn'),
                            onPressed: _isSubmitting
                                ? null
                                : () => _submitPayment('simulated_failure'),
                            icon: const Icon(Icons.error_outline, size: 18),
                            label: const Text('Simulate Failure'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: const BorderSide(color: AppTheme.errorRed),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Option 2: Pay at Location
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_outlined, color: AppTheme.accentOrange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pay at Location',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Submit your booking without online payment and pay directly at the service location.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        key: const Key('pay_at_location_btn'),
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitPayment('at_location'),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Select Pay at Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isSubmitting) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentOrange),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/bookings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryNavy,
                      side: const BorderSide(color: AppTheme.primaryNavy),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('View My Bookings'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
