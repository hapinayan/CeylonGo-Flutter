/// Booking and Payment domain models matching CeylonGo Academic MVP OpenAPI v1.1.0.
class PaymentRecord {
  final int id;
  final int bookingId;
  final String requestKey;
  final int attemptNo;
  final String method; // 'simulated' | 'at_location'
  final String status; // 'demo_succeeded' | 'demo_failed' | 'unpaid'
  final String displayAmount;
  final String currency;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const PaymentRecord({
    required this.id,
    required this.bookingId,
    required this.requestKey,
    required this.attemptNo,
    required this.method,
    required this.status,
    required this.displayAmount,
    this.currency = 'LKR',
    this.createdAt,
    this.resolvedAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      bookingId: json['booking_id'] is int
          ? json['booking_id'] as int
          : int.tryParse('${json['booking_id']}') ?? 0,
      requestKey: json['request_key']?.toString() ?? '',
      attemptNo: json['attempt_no'] is int
          ? json['attempt_no'] as int
          : int.tryParse('${json['attempt_no']}') ?? 1,
      method: json['method']?.toString() ?? 'simulated',
      status: json['status']?.toString() ?? 'unpaid',
      displayAmount: json['display_amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
    );
  }

  String get readableLabel {
    if (method == 'at_location') {
      return 'Pay at Location (Unpaid)';
    }
    switch (status) {
      case 'demo_succeeded':
        return 'Simulated Payment Succeeded (Demo)';
      case 'demo_failed':
        return 'Simulated Payment Failed (Demo)';
      default:
        return 'Simulated Payment ($status)';
    }
  }
}

class TravelerContactInfo {
  final String fullName;
  final String email;
  final String? phone;

  const TravelerContactInfo({
    required this.fullName,
    required this.email,
    this.phone,
  });

  factory TravelerContactInfo.fromJson(Map<String, dynamic> json) {
    return TravelerContactInfo(
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }
}

class BookingRecord {
  final int id;
  final int listingId;
  final int travelerId;
  final String requestKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final int quantity;
  final String totalAmount;
  final String currency;
  final String status; // 'pending' | 'confirmed' | 'rejected' | 'cancelled' | 'completed'
  final DateTime createdAt;
  final String? bookingReference;
  final int? slotId;
  final int? packageId;
  final List<int> rentalUnitIds;
  final List<int> roomIds;
  final List<PaymentRecord> payments;
  final TravelerContactInfo? travelerContact;

  const BookingRecord({
    required this.id,
    required this.listingId,
    required this.travelerId,
    required this.requestKey,
    required this.startsAt,
    required this.endsAt,
    required this.quantity,
    required this.totalAmount,
    this.currency = 'LKR',
    required this.status,
    required this.createdAt,
    this.bookingReference,
    this.slotId,
    this.packageId,
    this.rentalUnitIds = const [],
    this.roomIds = const [],
    this.payments = const [],
    this.travelerContact,
  });

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    List<int> parseIds(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    final rawPayments = json['payments'];
    final paymentList = <PaymentRecord>[];
    if (rawPayments is List) {
      for (final p in rawPayments) {
        if (p is Map<String, dynamic>) {
          paymentList.add(PaymentRecord.fromJson(p));
        }
      }
    }

    return BookingRecord(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      listingId: json['listing_id'] is int
          ? json['listing_id'] as int
          : int.tryParse('${json['listing_id']}') ?? 0,
      travelerId: json['traveler_id'] is int
          ? json['traveler_id'] as int
          : int.tryParse('${json['traveler_id']}') ?? 0,
      requestKey: json['request_key']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '') ??
          DateTime.now(),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 1,
      totalAmount: json['total_amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'LKR',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      bookingReference: json['booking_reference']?.toString(),
      slotId: json['slot_id'] is int
          ? json['slot_id'] as int
          : int.tryParse('${json['slot_id']}'),
      packageId: json['package_id'] is int
          ? json['package_id'] as int
          : int.tryParse('${json['package_id']}'),
      rentalUnitIds: parseIds(json['rental_unit_ids']),
      roomIds: parseIds(json['room_ids']),
      payments: paymentList,
      travelerContact: json['traveler_contact'] is Map<String, dynamic>
          ? TravelerContactInfo.fromJson(
              json['traveler_contact'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  PaymentRecord? get latestPayment => payments.isEmpty ? null : payments.last;

  bool get hasAcceptedPaymentMethod => payments.any(
        (p) => p.status == 'demo_succeeded' || p.status == 'unpaid',
      );

  int get nextPaymentAttemptNo =>
      payments.isEmpty ? 1 : (payments.map((p) => p.attemptNo).reduce((a, b) => a > b ? a : b) + 1);
}
