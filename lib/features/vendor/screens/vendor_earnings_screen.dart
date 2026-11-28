import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/vendor_models.dart';
import '../models/wallet_commission_models.dart';
import '../services/demo_wallet_service.dart';
import '../services/real_earnings_api_service.dart';
import '../services/vendor_demo_service.dart';

/// Vendor Earnings, Settlements & Wallet/Commission Screen.
///
/// Strictly separates two modes:
/// 1. **Real Provider Mode** (authenticated non-demo provider JWT):
///    Calls verified read-only FastAPI endpoints and explicitly states that
///    wallet balance/top-up is unavailable from the current backend.
/// 2. **Offline Demo Mode**:
///    Displays local demo earnings plus the clearly labeled
///    `Demo Wallet — Simulated Transactions Only` simulator.
class VendorEarningsScreen extends StatefulWidget {
  final RealEarningsApiService? earningsApiService;
  final SecureStorageService? storageService;
  final DemoWalletService? demoWalletService;
  final String? realAuthToken;

  const VendorEarningsScreen({
    super.key,
    this.earningsApiService,
    this.storageService,
    this.demoWalletService,
    this.realAuthToken,
  });

  @override
  State<VendorEarningsScreen> createState() => _VendorEarningsScreenState();
}

class _VendorEarningsScreenState extends State<VendorEarningsScreen> {
  final VendorDemoService _service = VendorDemoService.instance;
  late final DemoWalletService _wallet;
  late final RealEarningsApiService _realApi;

  String _dateFilter = 'All'; // All | Dec 2026 | Completed | Pending
  int _simBookingCounter = 0;
  String? _walletFeedback;
  bool _walletFeedbackIsError = false;

  // Real Provider Mode state
  String? _activeRealToken;
  bool _isLoadingReal = false;
  String? _realError;
  RealProviderEarningsSummary? _realSummary;
  RealProviderSettlementPage? _realSettlements;

  bool get _isRealMode {
    final t = _activeRealToken?.trim();
    return t != null && t.isNotEmpty && !t.startsWith('demo-');
  }

  @override
  void initState() {
    super.initState();
    _wallet = widget.demoWalletService ?? DemoWalletService.instance;
    _realApi = widget.earningsApiService ?? RealEarningsApiService();

    final injected = widget.realAuthToken?.trim();
    if (injected != null && injected.isNotEmpty && !injected.startsWith('demo-')) {
      _activeRealToken = injected;
      _loadRealEarnings();
    } else if (widget.storageService != null &&
        !_service.currentVendor.isDemoSession) {
      _resolveStoredProviderToken();
    }
  }

  Future<void> _resolveStoredProviderToken() async {
    try {
      final token = await widget.storageService!.getToken();
      final user = await widget.storageService!.getUser();
      if (!mounted) return;
      if (token != null &&
          token.trim().isNotEmpty &&
          !token.startsWith('demo-') &&
          user?.role == 'provider') {
        setState(() {
          _activeRealToken = token.trim();
        });
        await _loadRealEarnings();
      }
    } catch (_) {
      // Remain in Demo Mode if storage cannot be read.
    }
  }

  Future<void> _loadRealEarnings() async {
    if (!_isRealMode) return;
    setState(() {
      _isLoadingReal = true;
      _realError = null;
    });

    try {
      final token = _activeRealToken!.trim();
      final results = await Future.wait([
        _realApi.getProviderEarningsSummary(token),
        _realApi.getProviderSettlements(token),
      ]);
      if (!mounted) return;
      setState(() {
        _isLoadingReal = false;
        _realSummary = results[0] as RealProviderEarningsSummary;
        _realSettlements = results[1] as RealProviderSettlementPage;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingReal = false;
        _realError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingReal = false;
        _realError = 'Unable to load provider earnings right now.';
      });
    }
  }

  String _formatLkr(num amount) {
    final rounded = amount.round();
    final isNeg = rounded < 0;
    final s = rounded.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${isNeg ? '-' : ''}LKR ${buf.toString()}';
  }

  String _formatDecimalLkr(double amount, {String currency = 'LKR'}) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  Future<void> _showTopUpDialog() async {
    final controller = TextEditingController(text: '1000');
    String? dialogError;
    bool submitted = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('demo_topup_dialog'),
          title: const Text('Simulated Wallet Top-Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demo Only: Add simulated LKR credit locally. No card details or real payment gateway are used.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [500, 1000, 5000].map((preset) {
                  return ActionChip(
                    key: Key('demo_topup_preset_$preset'),
                    label: Text('LKR $preset'),
                    onPressed: () {
                      controller.text = '$preset';
                      setDialogState(() => dialogError = null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('demo_topup_amount_field'),
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (LKR)',
                  errorText: dialogError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('demo_topup_confirm_btn'),
              onPressed: submitted
                  ? null
                  : () {
                      final raw = controller.text.trim();
                      final parsed = int.tryParse(raw);
                      if (parsed == null) {
                        setDialogState(
                          () => dialogError = 'Enter a whole LKR amount.',
                        );
                        return;
                      }
                      submitted = true;
                      final res = _wallet.topUp(
                        amountLkr: parsed,
                        idempotencyKey:
                            'ui_${DateTime.now().microsecondsSinceEpoch}',
                      );
                      if (!res.success) {
                        submitted = false;
                        setDialogState(() => dialogError = res.message);
                        return;
                      }
                      setState(() {
                        _walletFeedback = res.message;
                        _walletFeedbackIsError = false;
                      });
                      Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Demo Credit'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _simulateCompletedBooking() {
    final nextNum = ++_simBookingCounter;
    final res = _wallet.processBooking(
      bookingId: 'sim_bk_$nextNum',
      bookingLabel: 'Simulated Booking #$nextNum',
      bookingAmountLkr: 5000,
      status: VendorBookingStatus.completed,
    );
    setState(() {
      _walletFeedback = res.message;
      _walletFeedbackIsError = !res.success;
    });
  }

  void _refundBookingCommission(String bookingId) {
    final res = _wallet.refundCommission(bookingId: bookingId);
    setState(() {
      _walletFeedback = res.message;
      _walletFeedbackIsError = !res.success;
    });
  }

  List<VendorBookingRequest> get _relevantBookings {
    final vendorListingTitles = _service.listings.map((l) => l.title).toSet();
    return _service.bookings
        .where((b) => vendorListingTitles.contains(b.listingTitle))
        .toList();
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
        actions: [
          if (_isRealMode)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadRealEarnings,
            ),
        ],
      ),
      body: SafeArea(
        child: _isRealMode ? _buildRealProviderView() : _buildDemoView(),
      ),
    );
  }

  Widget _buildRealProviderView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('real_wallet_unavailable_banner'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Text(
              'Wallet balance is not available from the current backend. Showing verified read-only provider earnings and settlements.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_isLoadingReal)
            const Padding(
              key: Key('real_earnings_loading'),
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryNavy),
              ),
            )
          else if (_realError != null)
            Container(
              key: const Key('real_earnings_error'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _realError!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    key: const Key('real_earnings_retry_btn'),
                    onPressed: _loadRealEarnings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_realSummary != null) ...[
            _SummaryCard(
              label: 'Net Payable (${_realSummary!.currency})',
              amount: _formatDecimalLkr(
                _realSummary!.netEarnings,
                currency: _realSummary!.currency,
              ),
              accentColor: const Color(0xFF0A4DF5),
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Gross Earnings',
                    amount: _formatDecimalLkr(
                      _realSummary!.grossEarnings,
                      currency: _realSummary!.currency,
                    ),
                    accentColor: const Color(0xFF16A34A),
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Platform Commission',
                    amount: _formatDecimalLkr(
                      _realSummary!.platformCommission,
                      currency: _realSummary!.currency,
                    ),
                    accentColor: const Color(0xFFEA580C),
                    icon: Icons.percent_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Settlements (${_realSummary!.totalSettlements})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            if (_realSettlements == null || _realSettlements!.items.isEmpty)
              const Text(
                'No settlement records found yet.',
                style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B)),
              )
            else
              Column(
                key: const Key('real_settlements_list'),
                children: _realSettlements!.items.map((s) {
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
                                '${s.periodStart} to ${s.periodEnd}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              Text(
                                'Status: ${s.status} • Commission: ${_formatDecimalLkr(s.platformCommission, currency: s.currency)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDecimalLkr(s.netPayable, currency: s.currency),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A4DF5),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoView() {
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

    return SingleChildScrollView(
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
          _buildDemoWalletSection(),
          const SizedBox(height: 16),
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
              children: ['All', 'Dec 2026', 'Completed', 'Pending'].map((filter) {
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
                      color: isSelected ? Colors.white : AppTheme.primaryNavy,
                    ),
                    onSelected: (_) => setState(() => _dateFilter = filter),
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
              final isCompleted = b.status == VendorBookingStatus.completed;
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
    );
  }

  Widget _buildDemoWalletSection() {
    final freeUsed = _wallet.freeBookingsUsed;
    final rate = _wallet.currentApplicableCommissionPercent;

    return Container(
      key: const Key('demo_wallet_section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Demo Wallet — Simulated Transactions Only',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              Container(
                key: const Key('demo_wallet_free_counter'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$freeUsed of 3 free used',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatLkr(_wallet.balanceLkr),
            key: const Key('demo_wallet_balance'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A4DF5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rate == 0
                ? 'Current commission rate: 0% (${_wallet.freeBookingsRemaining} free completed booking(s) remaining, then 10%).'
                : 'Current commission rate: 10% deducted per completed booking.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
          if (_walletFeedback != null) ...[
            const SizedBox(height: 10),
            Container(
              key: Key(
                _walletFeedbackIsError
                    ? 'demo_wallet_insufficient_banner'
                    : 'demo_wallet_success_banner',
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _walletFeedbackIsError
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _walletFeedbackIsError
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFA7F3D0),
                ),
              ),
              child: Text(
                _walletFeedback!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _walletFeedbackIsError
                      ? const Color(0xFF991B1B)
                      : const Color(0xFF065F46),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                key: const Key('demo_wallet_topup_btn'),
                onPressed: _showTopUpDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Simulated Top-Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('demo_wallet_simulate_booking_btn'),
                onPressed: _simulateCompletedBooking,
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Simulate Booking (LKR 5,000)'),
              ),
            ],
          ),
          if (_wallet.transactions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Demo Wallet Ledger',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              key: const Key('demo_wallet_tx_list'),
              children: _wallet.transactions.take(6).map((tx) {
                final canRefund =
                    tx.type == WalletTransactionType.commissionDeduction &&
                        tx.bookingId != null &&
                        !_wallet.hasRefundedBooking(tx.bookingId!);
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSlate),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Text(
                              tx.note,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatLkr(tx.amountDeltaLkr),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: tx.amountDeltaLkr < 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                          if (canRefund)
                            TextButton(
                              key: Key('demo_refund_btn_${tx.bookingId}'),
                              onPressed: () =>
                                  _refundBookingCommission(tx.bookingId!),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 24),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Refund',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
