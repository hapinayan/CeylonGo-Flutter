import '../models/vendor_models.dart';
import '../models/wallet_commission_models.dart';

/// Offline Demo Wallet & Commission Simulator.
///
/// IMPORTANT:
/// - In-memory educational simulation ONLY (`Demo Wallet — Simulated Transactions Only`).
/// - Never syncs to FastAPI, never touches real money, and never mixes with
///   real provider earnings or settlements.
class DemoWalletService {
  DemoWalletService._();

  static final DemoWalletService instance = DemoWalletService._();

  int _balanceLkr = 0;
  int _txCounter = 0;
  final Set<String> _eligibleBookingIds = <String>{};
  final Set<String> _refundedBookingIds = <String>{};
  final Set<String> _topUpKeys = <String>{};
  final List<DemoWalletTransaction> _transactions = <DemoWalletTransaction>[];

  int get balanceLkr => _balanceLkr;

  int get completedEligibleBookingsCount => _eligibleBookingIds.length;

  int get freeBookingsUsed =>
      _eligibleBookingIds.length < WalletCommissionPolicy.freeBookingAllowance
          ? _eligibleBookingIds.length
          : WalletCommissionPolicy.freeBookingAllowance;

  int get freeBookingsRemaining =>
      WalletCommissionPolicy.freeBookingAllowance - freeBookingsUsed;

  int get currentApplicableCommissionPercent =>
      freeBookingsRemaining > 0 ? 0 : WalletCommissionPolicy.commissionPercent;

  List<DemoWalletTransaction> get transactions =>
      List.unmodifiable(_transactions);

  bool hasProcessedBooking(String bookingId) =>
      _eligibleBookingIds.contains(bookingId.trim());

  bool hasRefundedBooking(String bookingId) =>
      _refundedBookingIds.contains(bookingId.trim());

  void reset({int initialBalanceLkr = 0}) {
    _balanceLkr = initialBalanceLkr < 0 ? 0 : initialBalanceLkr;
    _txCounter = 0;
    _eligibleBookingIds.clear();
    _refundedBookingIds.clear();
    _topUpKeys.clear();
    _transactions.clear();
  }

  /// Validates and applies a simulated LKR top-up (no payment gateway or card data).
  DemoWalletOperationResult topUp({
    required int amountLkr,
    String? idempotencyKey,
    DateTime? timestamp,
  }) {
    if (amountLkr < WalletCommissionPolicy.minTopUpLkr) {
      return const DemoWalletOperationResult(
        success: false,
        message:
            'Minimum simulated top-up is LKR ${WalletCommissionPolicy.minTopUpLkr}.',
      );
    }
    if (amountLkr > WalletCommissionPolicy.maxTopUpLkr) {
      return const DemoWalletOperationResult(
        success: false,
        message:
            'Maximum simulated top-up is LKR ${WalletCommissionPolicy.maxTopUpLkr}.',
      );
    }
    final cleanKey = idempotencyKey?.trim();
    if (cleanKey != null && cleanKey.isNotEmpty) {
      if (_topUpKeys.contains(cleanKey)) {
        return const DemoWalletOperationResult(
          success: false,
          duplicateRejected: true,
          message: 'Duplicate top-up request ignored.',
        );
      }
      _topUpKeys.add(cleanKey);
    }

    _balanceLkr += amountLkr;
    final tx = DemoWalletTransaction(
      id: 'sim_tx_${++_txCounter}',
      type: WalletTransactionType.topUp,
      title: 'Simulated Wallet Top-Up',
      bookingAmountLkr: 0,
      amountDeltaLkr: amountLkr,
      commissionRatePercent: 0,
      balanceAfterLkr: _balanceLkr,
      note: 'Demo credit added locally (no real payment processed).',
      createdAt: timestamp ?? DateTime.now(),
    );
    _transactions.insert(0, tx);
    return DemoWalletOperationResult(
      success: true,
      message: 'Simulated top-up of LKR $amountLkr added to Demo Wallet.',
      transaction: tx,
    );
  }

  /// Processes a simulated booking against the 3-free-bookings + 10% commission policy.
  ///
  /// - Pending/accepted/rejected bookings do NOT consume the free allowance.
  /// - Duplicate booking IDs are rejected without charging twice.
  /// - Insufficient balance leaves the wallet ledger and free counter unchanged.
  DemoWalletOperationResult processBooking({
    required String bookingId,
    required String bookingLabel,
    required int bookingAmountLkr,
    required VendorBookingStatus status,
    DateTime? timestamp,
  }) {
    final cleanId = bookingId.trim();
    if (cleanId.isEmpty || bookingAmountLkr <= 0) {
      return const DemoWalletOperationResult(
        success: false,
        message: 'Valid booking ID and positive LKR amount are required.',
      );
    }

    if (status != VendorBookingStatus.completed) {
      return const DemoWalletOperationResult(
        success: false,
        message:
            'Only completed bookings are eligible for commission evaluation. Pending or rejected bookings do not consume your free allowance.',
      );
    }

    if (_eligibleBookingIds.contains(cleanId)) {
      return const DemoWalletOperationResult(
        success: false,
        duplicateRejected: true,
        message: 'This booking has already been processed in Demo Wallet.',
      );
    }

    // Bookings 1..3 are commission-free (0%).
    if (_eligibleBookingIds.length < WalletCommissionPolicy.freeBookingAllowance) {
      _eligibleBookingIds.add(cleanId);
      final used = _eligibleBookingIds.length;
      final tx = DemoWalletTransaction(
        id: 'sim_tx_${++_txCounter}',
        type: WalletTransactionType.commissionFreeBooking,
        bookingId: cleanId,
        title: bookingLabel,
        bookingAmountLkr: bookingAmountLkr,
        amountDeltaLkr: 0,
        commissionRatePercent: 0,
        balanceAfterLkr: _balanceLkr,
        note:
            'Commission-free booking ($used of ${WalletCommissionPolicy.freeBookingAllowance} allowance used).',
        createdAt: timestamp ?? DateTime.now(),
      );
      _transactions.insert(0, tx);
      return DemoWalletOperationResult(
        success: true,
        wasFreeBooking: true,
        commissionChargedLkr: 0,
        message:
            'Booking finalized with 0% commission ($used of 3 free bookings used).',
        transaction: tx,
      );
    }

    // Booking 4+ incurs 10% commission deducted from simulated wallet balance.
    final commission =
        WalletCommissionPolicy.calculateCommissionLkr(bookingAmountLkr);
    if (_balanceLkr < commission) {
      return DemoWalletOperationResult(
        success: false,
        insufficientBalance: true,
        commissionChargedLkr: commission,
        message:
            'Insufficient Demo Wallet balance: LKR $commission commission required, but only LKR $_balanceLkr available. Top up to finalize.',
      );
    }

    _balanceLkr -= commission;
    _eligibleBookingIds.add(cleanId);
    final tx = DemoWalletTransaction(
      id: 'sim_tx_${++_txCounter}',
      type: WalletTransactionType.commissionDeduction,
      bookingId: cleanId,
      title: bookingLabel,
      bookingAmountLkr: bookingAmountLkr,
      amountDeltaLkr: -commission,
      commissionRatePercent: WalletCommissionPolicy.commissionPercent,
      balanceAfterLkr: _balanceLkr,
      note: '10% simulated platform commission deducted.',
      createdAt: timestamp ?? DateTime.now(),
    );
    _transactions.insert(0, tx);
    return DemoWalletOperationResult(
      success: true,
      wasFreeBooking: false,
      commissionChargedLkr: commission,
      message: '10% simulated commission (LKR $commission) deducted.',
      transaction: tx,
    );
  }

  /// Refunds a previously deducted simulated commission back to Demo Wallet.
  ///
  /// Does not reset prior free-booking allowance usage.
  DemoWalletOperationResult refundCommission({
    required String bookingId,
    int? refundAmountLkr,
    DateTime? timestamp,
  }) {
    final cleanId = bookingId.trim();
    if (cleanId.isEmpty) {
      return const DemoWalletOperationResult(
        success: false,
        message: 'Booking ID is required for a simulated commission refund.',
      );
    }
    if (_refundedBookingIds.contains(cleanId)) {
      return const DemoWalletOperationResult(
        success: false,
        duplicateRejected: true,
        message: 'Commission for this booking has already been refunded.',
      );
    }

    DemoWalletTransaction? priorCharge;
    for (final tx in _transactions) {
      if (tx.bookingId == cleanId &&
          tx.type == WalletTransactionType.commissionDeduction) {
        priorCharge = tx;
        break;
      }
    }

    if (priorCharge == null) {
      return const DemoWalletOperationResult(
        success: false,
        message: 'No prior commission deduction found for this booking.',
      );
    }

    final originalCommission = priorCharge.amountDeltaLkr.abs();
    final amountToRefund = refundAmountLkr ?? originalCommission;
    if (amountToRefund <= 0 || amountToRefund > originalCommission) {
      return DemoWalletOperationResult(
        success: false,
        message:
            'Refund amount must be between LKR 1 and LKR $originalCommission.',
      );
    }

    _balanceLkr += amountToRefund;
    _refundedBookingIds.add(cleanId);
    final tx = DemoWalletTransaction(
      id: 'sim_tx_${++_txCounter}',
      type: WalletTransactionType.commissionRefund,
      bookingId: cleanId,
      title: 'Commission Refund: ${priorCharge.title}',
      bookingAmountLkr: priorCharge.bookingAmountLkr,
      amountDeltaLkr: amountToRefund,
      commissionRatePercent: priorCharge.commissionRatePercent,
      balanceAfterLkr: _balanceLkr,
      note:
          'Simulated commission reversal credited to wallet. Prior free-booking usage remains unchanged.',
      createdAt: timestamp ?? DateTime.now(),
    );
    _transactions.insert(0, tx);
    return DemoWalletOperationResult(
      success: true,
      commissionChargedLkr: amountToRefund,
      message: 'Simulated commission refund of LKR $amountToRefund credited.',
      transaction: tx,
    );
  }
}

