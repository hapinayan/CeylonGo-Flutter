// Strongly typed models for:
// 1. Verified FastAPI Read-Only Provider Earnings & Settlement endpoints
// 2. Offline Demo Wallet & Commission Simulator (clearly separated from real money)

class RealProviderEarningsSummary {
  final double grossEarnings;
  final double platformCommission;
  final double netEarnings;
  final double verifiedRefunds;
  final double availableSettlementBalance;
  final double totalSettled;
  final double pendingSettlement;
  final String currency;
  final int totalSettlements;
  final int pendingSettlements;
  final int completedSettlements;
  final int? totalPaidBookings;
  final String sourceEndpoint;

  const RealProviderEarningsSummary({
    required this.grossEarnings,
    required this.platformCommission,
    required this.netEarnings,
    this.verifiedRefunds = 0.0,
    this.availableSettlementBalance = 0.0,
    this.totalSettled = 0.0,
    this.pendingSettlement = 0.0,
    this.currency = 'LKR',
    this.totalSettlements = 0,
    this.pendingSettlements = 0,
    this.completedSettlements = 0,
    this.totalPaidBookings,
    required this.sourceEndpoint,
  });

  /// Parses `GET /api/v1/providers/me/earnings/summary`.
  factory RealProviderEarningsSummary.fromProviderDashboardJson(
    Map<String, dynamic> json,
  ) {
    return RealProviderEarningsSummary(
      grossEarnings: _asDouble(json['gross_earnings']) ?? 0.0,
      platformCommission: _asDouble(json['platform_commission']) ?? 0.0,
      netEarnings: _asDouble(json['net_payable']) ?? 0.0,
      currency: _asString(json['currency']) ?? 'LKR',
      totalSettlements: _asInt(json['total_settlements']) ?? 0,
      pendingSettlements: _asInt(json['pending_settlements']) ?? 0,
      completedSettlements: _asInt(json['completed_settlements']) ?? 0,
      sourceEndpoint: '/api/v1/providers/me/earnings/summary',
    );
  }

  /// Parses `GET /api/v1/payments/provider/earnings`.
  factory RealProviderEarningsSummary.fromPaymentsProviderJson(
    Map<String, dynamic> json,
  ) {
    return RealProviderEarningsSummary(
      grossEarnings: _asDouble(json['total_gross_earnings']) ?? 0.0,
      platformCommission: _asDouble(json['ceylongo_commission']) ?? 0.0,
      netEarnings: _asDouble(json['provider_net_earnings']) ?? 0.0,
      verifiedRefunds: _asDouble(json['verified_refunds']) ?? 0.0,
      availableSettlementBalance:
          _asDouble(json['available_settlement_balance']) ?? 0.0,
      totalSettled: _asDouble(json['total_settled']) ?? 0.0,
      pendingSettlement: _asDouble(json['pending_settlement']) ?? 0.0,
      currency: _asString(json['currency']) ?? 'LKR',
      totalPaidBookings: _asInt(json['total_paid_bookings']),
      sourceEndpoint: '/api/v1/payments/provider/earnings',
    );
  }
}

class RealProviderSettlement {
  final int id;
  final int providerProfileId;
  final String periodStart;
  final String periodEnd;
  final double grossEarnings;
  final double platformCommission;
  final double netPayable;
  final String currency;
  final String status;
  final String? settlementReference;
  final DateTime? settledAt;

  const RealProviderSettlement({
    required this.id,
    required this.providerProfileId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossEarnings,
    required this.platformCommission,
    required this.netPayable,
    required this.currency,
    required this.status,
    this.settlementReference,
    this.settledAt,
  });

  factory RealProviderSettlement.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null || id <= 0) {
      throw const FormatException('Missing settlement ID.');
    }
    return RealProviderSettlement(
      id: id,
      providerProfileId: _asInt(json['provider_profile_id']) ?? 0,
      periodStart: _asString(json['period_start']) ?? '',
      periodEnd: _asString(json['period_end']) ?? '',
      grossEarnings: _asDouble(json['gross_earnings']) ??
          _asDouble(json['gross_amount']) ??
          0.0,
      platformCommission: _asDouble(json['platform_commission']) ??
          _asDouble(json['platform_fee']) ??
          0.0,
      netPayable: _asDouble(json['net_payable']) ?? 0.0,
      currency: _asString(json['currency']) ?? 'LKR',
      status: _asString(json['status']) ??
          _asString(json['settlement_status']) ??
          'pending',
      settlementReference: _asString(json['settlement_reference']) ??
          _asString(json['payout_reference']),
      settledAt: _parseDate(json['settled_at'] ?? json['paid_at']),
    );
  }
}

class RealProviderSettlementPage {
  final List<RealProviderSettlement> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const RealProviderSettlementPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory RealProviderSettlementPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Missing items in settlement response.');
    }
    final parsed = rawItems
        .whereType<Map>()
        .map(
          (e) => RealProviderSettlement.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    return RealProviderSettlementPage(
      items: parsed,
      total: _asInt(json['total']) ?? parsed.length,
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['page_size']) ?? 20,
      totalPages: _asInt(json['total_pages']) ?? 1,
    );
  }
}

// =============================================================================
// OFFLINE DEMO WALLET & COMMISSION SIMULATOR MODELS
// =============================================================================

enum WalletTransactionType {
  topUp,
  commissionFreeBooking,
  commissionDeduction,
  commissionRefund,
}

class WalletCommissionPolicy {
  static const String currency = 'LKR';
  static const int freeBookingAllowance = 3;
  static const int commissionPercent = 10;
  static const int minTopUpLkr = 100;
  static const int maxTopUpLkr = 500000;

  /// Calculates 10% commission in whole LKR using half-up integer rounding.
  /// Example: 1254 -> 125, 1255 -> 126.
  static int calculateCommissionLkr(int bookingAmountLkr) {
    if (bookingAmountLkr <= 0) return 0;
    return (bookingAmountLkr * commissionPercent + 50) ~/ 100;
  }
}

class DemoWalletTransaction {
  final String id;
  final WalletTransactionType type;
  final String? bookingId;
  final String title;
  final int bookingAmountLkr;
  final int amountDeltaLkr;
  final int commissionRatePercent;
  final int balanceAfterLkr;
  final String note;
  final DateTime createdAt;

  const DemoWalletTransaction({
    required this.id,
    required this.type,
    this.bookingId,
    required this.title,
    required this.bookingAmountLkr,
    required this.amountDeltaLkr,
    required this.commissionRatePercent,
    required this.balanceAfterLkr,
    required this.note,
    required this.createdAt,
  });
}

class DemoWalletOperationResult {
  final bool success;
  final bool wasFreeBooking;
  final bool insufficientBalance;
  final bool duplicateRejected;
  final int commissionChargedLkr;
  final String message;
  final DemoWalletTransaction? transaction;

  const DemoWalletOperationResult({
    required this.success,
    this.wasFreeBooking = false,
    this.insufficientBalance = false,
    this.duplicateRejected = false,
    this.commissionChargedLkr = 0,
    required this.message,
    this.transaction,
  });
}

double? _asDouble(dynamic value) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final p = double.tryParse(value.trim());
    if (p != null && p.isFinite) return p;
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num && value.isFinite) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _asString(dynamic value) {
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

