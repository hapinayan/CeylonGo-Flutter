import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../bookings/models/booking_models.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_planner_api_models.dart';
import 'package:flutter/material.dart';

/// Service connecting CeylonGo AI Travel Planner & Itinerary Generator
/// to the running FastAPI Academic MVP backend.
class AiPlannerService {
  final ApiClient _api;

  AiPlannerService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<PlannerThread> createConversation({required String title}) async {
    final data = await _api.post(
      ApiConstants.aiPlannerConversationsEndpoint,
      body: {'title': title.trim()},
    );
    return PlannerThread.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PlannerThread>> getConversations() async {
    final data = await _api.get(ApiConstants.aiPlannerConversationsEndpoint);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PlannerThread.fromJson)
          .toList();
    }
    return [];
  }

  Future<PlannerThread> renameConversation(int id, {required String title}) async {
    final data = await _api.patch(
      '${ApiConstants.aiPlannerConversationsEndpoint}/$id',
      body: {'title': title.trim()},
    );
    return PlannerThread.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteConversation(int id) async {
    await _api.delete('${ApiConstants.aiPlannerConversationsEndpoint}/$id');
  }

  Future<List<PlannerTurn>> getMessages(
    int conversationId, {
    int limit = 30,
  }) async {
    final data = await _api.get(
      '${ApiConstants.aiPlannerConversationsEndpoint}/$conversationId/messages',
      queryParameters: {'limit': limit.toString()},
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PlannerTurn.fromJson)
          .toList();
    }
    return [];
  }

  Future<PlannerTurn> sendMessage(
    int conversationId, {
    required String text,
  }) async {
    final data = await _api.post(
      '${ApiConstants.aiPlannerConversationsEndpoint}/$conversationId/messages',
      body: {'text': text.trim()},
    );
    return PlannerTurn.fromJson(data as Map<String, dynamic>);
  }

  Future<PlannerProposal> createBookingQuote({
    required int listingId,
    int quantity = 1,
    DateTime? startsAt,
    DateTime? endsAt,
    String? day,
    int? roomId,
    int? slotId,
    int? packageId,
  }) async {
    final payload = <String, dynamic>{
      'listing_id': listingId,
      'quantity': quantity,
      if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
      if (day != null) 'day': day,
      if (roomId != null) 'room_id': roomId,
      if (slotId != null) 'slot_id': slotId,
      if (packageId != null) 'package_id': packageId,
    };
    final data = await _api.post(
      ApiConstants.aiPlannerBookingQuotesEndpoint,
      body: payload,
    );
    return PlannerProposal.fromJson(data as Map<String, dynamic>);
  }

  Future<BookingRecord> confirmBooking({
    required String confirmationToken,
    bool motorcycleLicenseConfirmed = false,
    String? licenseValidUntil,
  }) async {
    final payload = <String, dynamic>{
      'confirmation_token': confirmationToken,
      'confirm': true,
      'motorcycle_license_confirmed': motorcycleLicenseConfirmed,
      if (licenseValidUntil != null) 'license_valid_until': licenseValidUntil,
    };
    final data = await _api.post(
      ApiConstants.aiPlannerBookingsConfirmEndpoint,
      body: payload,
    );
    return BookingRecord.fromJson(data as Map<String, dynamic>);
  }

  Future<PlannerSavedTrip> saveTrip({
    required String title,
    required int turnId,
  }) async {
    final data = await _api.post(
      ApiConstants.aiPlannerTripsEndpoint,
      body: {'title': title.trim(), 'turn_id': turnId},
    );
    return PlannerSavedTrip.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PlannerSavedTrip>> getSavedTrips() async {
    final data = await _api.get(ApiConstants.aiPlannerTripsEndpoint);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PlannerSavedTrip.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> deleteSavedTrip(int tripId) async {
    await _api.delete('${ApiConstants.aiPlannerTripsEndpoint}/$tripId');
  }

  /// POST /api/v1/itinerary/generate
  Future<({String summaryText, TravelPlanCardData card})> generateItinerary({
    required String destination,
    int durationDays = 3,
    String budgetLevel = 'moderate',
    List<String> interests = const ['culture', 'nature'],
  }) async {
    final data = await _api.post(
      ApiConstants.itineraryGenerateEndpoint,
      body: {
        'destination': destination.trim(),
        'duration_days': durationDays,
        'budget_level': budgetLevel,
        'interests': interests,
      },
    );
    final map = data as Map<String, dynamic>;
    final rawDays = (map['days'] as List?) ?? const [];
    const palette = [
      Color(0xFF0A4DF5),
      Color(0xFF059669),
      Color(0xFFEA580C),
      Color(0xFF082B5C),
    ];
    final days = rawDays.whereType<Map<String, dynamic>>().map((d) {
      final dayNum = d['day'] is int ? d['day'] as int : 1;
      return ItineraryDayItem(
        dayLabel: 'DAY $dayNum',
        title: d['title']?.toString() ?? 'Day $dayNum',
        description:
            '${d['morning'] ?? ''} • ${d['afternoon'] ?? ''} • ${d['evening'] ?? ''}',
        imageUrl: '',
        fallbackIcon: Icons.place_outlined,
        fallbackColor: palette[(dayNum - 1) % palette.length],
      );
    }).toList();

    final tips = (map['tips'] as List?)?.map((e) => '• $e').join('\n') ?? '';
    final cost = map['total_estimated_cost_lkr']?.toString() ?? '0';
    return (
      summaryText:
          'Generated a $durationDays-day $budgetLevel itinerary for $destination (Est. LKR $cost).\n$tips',
      card: TravelPlanCardData(
        title: '$durationDays-Day $destination Itinerary',
        categoryBadge: 'Est. LKR $cost',
        days: days,
      ),
    );
  }
}
