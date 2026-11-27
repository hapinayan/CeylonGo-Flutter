import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/constants/api_constants.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/vendor/models/vendor_models.dart';
import 'package:ceylongo/features/vendor/models/wallet_commission_models.dart';
import 'package:ceylongo/features/vendor/screens/vendor_earnings_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_more_screen.dart';
import 'package:ceylongo/features/vendor/services/demo_wallet_service.dart';
import 'package:ceylongo/features/vendor/services/real_earnings_api_service.dart';
import 'package:ceylongo/main.dart';

Map<String, dynamic> _sampleDashboardSummaryJson() => {
      'gross_earnings': '45000.00',
      'platform_commission': '4500.00',
      'net_payable': '40500.00',
      'currency': 'LKR',
      'total_settlements': 2,
      'pending_settlements': 1,
      'completed_settlements': 1,
    };

Map<String, dynamic> _sampleSettlementPageJson() => {
      'items': [
        {
          'id': 12,
          'provider_profile_id': 5,
          'period_start': '2026-11-01',
          'period_end': '2026-11-15',
          'gross_earnings': '25000.00',
          'platform_commission': '2500.00',
          'net_payable': '22500.00',
          'currency': 'LKR',
          'status': 'paid',
          'settlement_reference': 'SET-2026-11-A',
          'settled_at': '2026-11-16T10:00:00',
          'created_at': '2026-11-16T09:00:00',
        },
      ],
      'total': 1,
      'page': 1,
      'page_size': 20,
      'total_pages': 1,
    };

void main() {
  setUp(() {
    DemoWalletService.instance.reset();
  });

  group('DemoWalletService & Commission Policy Unit Tests', () {
    test('starts at LKR 0, validates top-up, and prevents duplicate top-up', () {
      final wallet = DemoWalletService.instance;
      expect(wallet.balanceLkr, 0);

      // Invalid amounts rejected
      expect(wallet.topUp(amountLkr: 0).success, isFalse);
      expect(wallet.topUp(amountLkr: -500).success, isFalse);
      expect(wallet.topUp(amountLkr: 50).success, isFalse);
      expect(wallet.topUp(amountLkr: 600000).success, isFalse);
      expect(wallet.balanceLkr, 0);

      // Valid top-up
      final ok = wallet.topUp(amountLkr: 1500, idempotencyKey: 'topup_1');
      expect(ok.success, isTrue);
      expect(wallet.balanceLkr, 1500);
      expect(wallet.transactions, hasLength(1));

      // Duplicate top-up rejected
      final dup = wallet.topUp(amountLkr: 1500, idempotencyKey: 'topup_1');
      expect(dup.success, isFalse);
      expect(dup.duplicateRejected, isTrue);
      expect(wallet.balanceLkr, 1500);
    });

    test('enforces first 3 commission-free bookings, ignores pending/rejected, and charges 10% on 4th+', () {
      final wallet = DemoWalletService.instance;
      wallet.topUp(amountLkr: 2000);

      // Pending and rejected bookings do NOT consume free allowance
      final pending = wallet.processBooking(
        bookingId: 'b_pending',
        bookingLabel: 'Pending Stay',
        bookingAmountLkr: 10000,
        status: VendorBookingStatus.pending,
      );
      final rejected = wallet.processBooking(
        bookingId: 'b_rejected',
        bookingLabel: 'Rejected Stay',
        bookingAmountLkr: 10000,
        status: VendorBookingStatus.rejected,
      );
      expect(pending.success, isFalse);
      expect(rejected.success, isFalse);
      expect(wallet.freeBookingsUsed, 0);

      // Bookings 1, 2, 3 -> 0% commission
      for (var i = 1; i <= 3; i++) {
        final res = wallet.processBooking(
          bookingId: 'b_$i',
          bookingLabel: 'Stay #$i',
          bookingAmountLkr: 10000,
          status: VendorBookingStatus.completed,
        );
        expect(res.success, isTrue);
        expect(res.wasFreeBooking, isTrue);
        expect(res.commissionChargedLkr, 0);
      }
      expect(wallet.freeBookingsUsed, 3);
      expect(wallet.freeBookingsRemaining, 0);
      expect(wallet.currentApplicableCommissionPercent, 10);
      expect(wallet.balanceLkr, 2000);

      // Duplicate booking rejected
      final dup = wallet.processBooking(
        bookingId: 'b_1',
        bookingLabel: 'Stay #1',
        bookingAmountLkr: 10000,
        status: VendorBookingStatus.completed,
      );
      expect(dup.duplicateRejected, isTrue);
      expect(wallet.balanceLkr, 2000);

      // Booking 4 -> 10% commission (10% of 10000 = 1000)
      final b4 = wallet.processBooking(
        bookingId: 'b_4',
        bookingLabel: 'Stay #4',
        bookingAmountLkr: 10000,
        status: VendorBookingStatus.completed,
      );
      expect(b4.success, isTrue);
      expect(b4.wasFreeBooking, isFalse);
      expect(b4.commissionChargedLkr, 1000);
      expect(wallet.balanceLkr, 1000);
    });

    test('rounds 10% commission half-up in whole LKR', () {
      expect(WalletCommissionPolicy.calculateCommissionLkr(1254), 125);
      expect(WalletCommissionPolicy.calculateCommissionLkr(1255), 126);
      expect(WalletCommissionPolicy.calculateCommissionLkr(0), 0);
    });

    test('rejects insufficient balance without corrupting ledger and supports commission refund without duplicate refund', () {
      final wallet = DemoWalletService.instance;
      wallet.topUp(amountLkr: 600);
      for (var i = 1; i <= 3; i++) {
        wallet.processBooking(
          bookingId: 'f_$i',
          bookingLabel: 'Free #$i',
          bookingAmountLkr: 4000,
          status: VendorBookingStatus.completed,
        );
      }

      // 4th booking requires 800 LKR commission, only 600 available -> rejected
      final insuff = wallet.processBooking(
        bookingId: 'paid_1',
        bookingLabel: 'Paid #1',
        bookingAmountLkr: 8000,
        status: VendorBookingStatus.completed,
      );
      expect(insuff.success, isFalse);
      expect(insuff.insufficientBalance, isTrue);
      expect(wallet.balanceLkr, 600);
      expect(wallet.hasProcessedBooking('paid_1'), isFalse);

      // Top up 500 -> balance 1100 -> now succeeds (deducts 800 -> 300 left)
      wallet.topUp(amountLkr: 500);
      final paid = wallet.processBooking(
        bookingId: 'paid_1',
        bookingLabel: 'Paid #1',
        bookingAmountLkr: 8000,
        status: VendorBookingStatus.completed,
      );
      expect(paid.success, isTrue);
      expect(wallet.balanceLkr, 300);

      // Refund paid_1 -> balance returns to 1100; free allowance stays 3 of 3 used
      final refund = wallet.refundCommission(bookingId: 'paid_1');
      expect(refund.success, isTrue);
      expect(wallet.balanceLkr, 1100);
      expect(wallet.freeBookingsUsed, 3);

      // Duplicate refund rejected
      final dupRefund = wallet.refundCommission(bookingId: 'paid_1');
      expect(dupRefund.success, isFalse);
      expect(dupRefund.duplicateRejected, isTrue);
      expect(wallet.balanceLkr, 1100);
    });
  });

  group('RealEarningsApiService HTTP & Error Handling Tests', () {
    test('fetches and parses earnings summary and settlements with Bearer token',
        () async {
      final captured = <http.Request>[];
      final client = MockClient((request) async {
        captured.add(request);
        if (request.url.path.endsWith('/earnings/summary')) {
          return http.Response(jsonEncode(_sampleDashboardSummaryJson()), 200);
        }
        return http.Response(jsonEncode(_sampleSettlementPageJson()), 200);
      });

      final api = RealEarningsApiService(client: client);
      final summary = await api.getProviderEarningsSummary('real-provider-jwt');
      final settlements = await api.getProviderSettlements('real-provider-jwt');

      expect(captured[0].url.toString(), ApiConstants.providerEarningsSummaryEndpoint);
      expect(captured[0].headers['Authorization'], 'Bearer real-provider-jwt');
      expect(summary.grossEarnings, 45000.0);
      expect(summary.platformCommission, 4500.0);
      expect(summary.netEarnings, 40500.0);
      expect(settlements.items, hasLength(1));
      expect(settlements.items.first.netPayable, 22500.0);
    });

    test('rejects demo- tokens and handles 401, 403, 503, timeout, and SocketException',
        () async {
      final api = RealEarningsApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      expect(
        () => api.getProviderEarningsSummary('demo-vendor-token'),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 401)),
      );

      for (final code in [401, 403, 404, 422, 429, 503]) {
        final errApi = RealEarningsApiService(
          client: MockClient(
            (_) async => http.Response(jsonEncode({'detail': 'Err $code'}), code),
          ),
        );
        expect(
          () => errApi.getProviderEarningsSummary('real-jwt'),
          throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', code)),
        );
      }

      final timeoutApi = RealEarningsApiService(
        client: MockClient((_) async => throw TimeoutException('timeout')),
      );
      expect(
        () => timeoutApi.getProviderSettlements('real-jwt'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );

      final offlineApi = RealEarningsApiService(
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      expect(
        () => offlineApi.getProviderSettlements('real-jwt'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    });
  });

  group('VendorEarningsScreen Wallet & Real Mode Widget Tests', () {
    testWidgets(
      'Demo Mode: Renders Demo Wallet, top-up, 3 free bookings, 4th insufficient balance, top-up & refund on 360x800',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VendorEarningsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('demo_wallet_section')), findsOneWidget);
        expect(find.text('LKR 0'), findsWidgets);
        expect(find.text('0 of 3 free used'), findsOneWidget);

        // Simulate 3 free bookings
        final simBtn = find.byKey(const Key('demo_wallet_simulate_booking_btn'));
        for (var i = 0; i < 3; i++) {
          await tester.tap(simBtn);
          await tester.pumpAndSettle();
        }
        expect(find.text('3 of 3 free used'), findsOneWidget);

        // 4th booking with LKR 0 balance -> Insufficient balance banner
        await tester.tap(simBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('demo_wallet_insufficient_banner')),
          findsOneWidget,
        );

        // Simulated Top-Up LKR 1,000 -> no card/bank fields
        await tester.tap(find.byKey(const Key('demo_wallet_topup_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('demo_topup_dialog')), findsOneWidget);
        await tester.tap(find.byKey(const Key('demo_topup_confirm_btn')));
        await tester.pumpAndSettle();
        expect(find.text('LKR 1,000'), findsWidgets);

        // Now 4th booking succeeds (deducts LKR 500 -> balance LKR 500)
        await tester.tap(simBtn);
        await tester.pumpAndSettle();
        expect(find.text('LKR 500'), findsWidgets);

        // Refund the 4th booking commission -> balance back to LKR 1,000
        final refundBtn = find.byKey(const Key('demo_refund_btn_sim_bk_5'));
        await tester.ensureVisible(refundBtn);
        await tester.pumpAndSettle();
        await tester.tap(refundBtn);
        await tester.pumpAndSettle();
        expect(find.text('LKR 1,000'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Real Provider Mode: Displays server earnings & settlements and states wallet balance unavailable on 360x800',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final client = MockClient((request) async {
          if (request.url.path.endsWith('/earnings/summary')) {
            return http.Response(jsonEncode(_sampleDashboardSummaryJson()), 200);
          }
          return http.Response(jsonEncode(_sampleSettlementPageJson()), 200);
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: VendorEarningsScreen(
              realAuthToken: 'real-provider-jwt',
              earningsApiService: RealEarningsApiService(client: client),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('real_wallet_unavailable_banner')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('demo_wallet_section')), findsNothing);
        expect(find.text('LKR 40500.00'), findsOneWidget);
        expect(find.byKey(const Key('real_settlements_list')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Navigates from Vendor More -> Earnings & Payments cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: CeylonGoApp.getRoutes(),
          home: const VendorMoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vendor_more_earnings_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(VendorEarningsScreen), findsOneWidget);
      expect(find.byKey(const Key('demo_wallet_section')), findsOneWidget);
    });
  });
}

