import 'package:flutter/material.dart';

import 'ai_chat_message.dart';

int _toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  return int.tryParse('$v') ?? fallback;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

class PlannerThread {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlannerThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlannerThread.fromJson(Map<String, dynamic> json) {
    return PlannerThread(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? 'Trip Plan',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class PlannerServiceOption {
  final int id;
  final String title;
  final int capacity;
  final String? advertisedPriceLkr;
  final String? pricingType;

  const PlannerServiceOption({
    required this.id,
    required this.title,
    required this.capacity,
    this.advertisedPriceLkr,
    this.pricingType,
  });

  factory PlannerServiceOption.fromJson(Map<String, dynamic> json) {
    return PlannerServiceOption(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      capacity: _toInt(json['capacity'], 1),
      advertisedPriceLkr: json['advertised_price_lkr']?.toString(),
      pricingType: json['pricing_type']?.toString(),
    );
  }
}

class PlannerListingResult {
  final String ref;
  final int listingId;
  final String category;
  final String title;
  final String district;
  final String locality;
  final String? advertisedPriceLkr;
  final double? latitude;
  final double? longitude;
  final List<PlannerServiceOption> options;

  const PlannerListingResult({
    required this.ref,
    required this.listingId,
    required this.category,
    required this.title,
    required this.district,
    required this.locality,
    this.advertisedPriceLkr,
    this.latitude,
    this.longitude,
    this.options = const [],
  });

  factory PlannerListingResult.fromJson(Map<String, dynamic> json) {
    final details = json['details'] is Map<String, dynamic>
        ? json['details'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawOpts = details['options'];
    final opts = <PlannerServiceOption>[];
    if (rawOpts is List) {
      for (final o in rawOpts) {
        if (o is Map<String, dynamic>) {
          opts.add(PlannerServiceOption.fromJson(o));
        }
      }
    }
    return PlannerListingResult(
      ref: json['ref']?.toString() ?? '',
      listingId: _toInt(json['listing_id']),
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      advertisedPriceLkr: json['advertised_price_lkr']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      options: opts,
    );
  }
}

class PlannerQuote {
  final int listingId;
  final String category;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final int quantity;
  final String totalLkr;
  final int? roomId;
  final int? slotId;
  final int? packageId;
  final bool motorcycleLicenseRequired;

  const PlannerQuote({
    required this.listingId,
    required this.category,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.quantity,
    required this.totalLkr,
    this.roomId,
    this.slotId,
    this.packageId,
    this.motorcycleLicenseRequired = false,
  });

  factory PlannerQuote.fromJson(Map<String, dynamic> json) {
    return PlannerQuote(
      listingId: _toInt(json['listing_id']),
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? '') ??
          DateTime.now(),
      quantity: _toInt(json['quantity'], 1),
      totalLkr: json['total_lkr']?.toString() ?? '0',
      roomId: json['room_id'] is int ? json['room_id'] as int : null,
      slotId: json['slot_id'] is int ? json['slot_id'] as int : null,
      packageId: json['package_id'] is int ? json['package_id'] as int : null,
      motorcycleLicenseRequired: json['motorcycle_license_required'] == true,
    );
  }
}

class PlannerProposal {
  final PlannerQuote quote;
  final String confirmationToken;
  final DateTime expiresAt;

  const PlannerProposal({
    required this.quote,
    required this.confirmationToken,
    required this.expiresAt,
  });

  factory PlannerProposal.fromJson(Map<String, dynamic> json) {
    return PlannerProposal(
      quote: PlannerQuote.fromJson(
        (json['quote'] as Map<String, dynamic>?) ?? const {},
      ),
      confirmationToken: json['confirmation_token']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class PlannerItinerary {
  final String title;
  final String summary;
  final String budgetLkr;
  final String estimatedTotalLkr;
  final String remainingBudgetLkr;
  final List<PlannerItineraryDay> days;

  const PlannerItinerary({
    required this.title,
    required this.summary,
    required this.budgetLkr,
    required this.estimatedTotalLkr,
    required this.remainingBudgetLkr,
    required this.days,
  });

  factory PlannerItinerary.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] is Map<String, dynamic>
        ? json['plan'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawDays = plan['days'];
    final days = <PlannerItineraryDay>[];
    if (rawDays is List) {
      for (final d in rawDays) {
        if (d is Map<String, dynamic>) {
          days.add(PlannerItineraryDay.fromJson(d));
        }
      }
    }
    return PlannerItinerary(
      title: plan['title']?.toString() ?? 'Sri Lanka Itinerary',
      summary: plan['summary']?.toString() ?? '',
      budgetLkr: plan['budget_lkr']?.toString() ?? '0',
      estimatedTotalLkr: json['estimated_total_lkr']?.toString() ?? '0',
      remainingBudgetLkr: json['remaining_budget_lkr']?.toString() ?? '0',
      days: days,
    );
  }

  TravelPlanCardData toCardData() {
    const palette = [
      Color(0xFF0A4DF5),
      Color(0xFF059669),
      Color(0xFFEA580C),
      Color(0xFF082B5C),
    ];
    return TravelPlanCardData(
      title: title,
      categoryBadge: 'LKR $estimatedTotalLkr',
      days: days
          .map(
            (d) => ItineraryDayItem(
              dayLabel: 'DAY ${d.day}',
              title: 'Day ${d.day} - ${d.destination}',
              description: '${d.morning} • ${d.afternoon} • ${d.evening}',
              imageUrl: '',
              fallbackIcon: Icons.explore_outlined,
              fallbackColor: palette[(d.day - 1) % palette.length],
            ),
          )
          .toList(),
    );
  }
}

class PlannerItineraryDay {
  final int day;
  final String destination;
  final String morning;
  final String afternoon;
  final String evening;
  final String transport;

  const PlannerItineraryDay({
    required this.day,
    required this.destination,
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.transport,
  });

  factory PlannerItineraryDay.fromJson(Map<String, dynamic> json) {
    return PlannerItineraryDay(
      day: _toInt(json['day'], 1),
      destination: json['destination']?.toString() ?? 'Sri Lanka',
      morning: json['morning']?.toString() ?? '',
      afternoon: json['afternoon']?.toString() ?? '',
      evening: json['evening']?.toString() ?? '',
      transport: json['transport']?.toString() ?? '',
    );
  }
}

class PlannerTurn {
  final int id;
  final String userMessage;
  final String assistantMessage;
  final PlannerItinerary? itinerary;
  final PlannerProposal? proposal;
  final List<PlannerListingResult> listings;
  final List<PlannerQuote> quotes;
  final DateTime createdAt;

  const PlannerTurn({
    required this.id,
    required this.userMessage,
    required this.assistantMessage,
    this.itinerary,
    this.proposal,
    this.listings = const [],
    this.quotes = const [],
    required this.createdAt,
  });

  factory PlannerTurn.fromJson(Map<String, dynamic> json) {
    final listings = <PlannerListingResult>[];
    if (json['listings'] is List) {
      for (final item in json['listings'] as List) {
        if (item is Map<String, dynamic>) {
          listings.add(PlannerListingResult.fromJson(item));
        }
      }
    }

    final quotes = <PlannerQuote>[];
    if (json['quotes'] is List) {
      for (final item in json['quotes'] as List) {
        if (item is Map<String, dynamic> && item['quote'] is Map<String, dynamic>) {
          quotes.add(PlannerQuote.fromJson(item['quote'] as Map<String, dynamic>));
        }
      }
    }

    return PlannerTurn(
      id: _toInt(json['id']),
      userMessage: json['user_message']?.toString() ?? '',
      assistantMessage: json['assistant_message']?.toString() ?? '',
      itinerary: json['itinerary'] is Map<String, dynamic>
          ? PlannerItinerary.fromJson(json['itinerary'] as Map<String, dynamic>)
          : null,
      proposal: json['proposal'] is Map<String, dynamic>
          ? PlannerProposal.fromJson(json['proposal'] as Map<String, dynamic>)
          : null,
      listings: listings,
      quotes: quotes,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class PlannerSavedTrip {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlannerItinerary itinerary;

  const PlannerSavedTrip({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.itinerary,
  });

  factory PlannerSavedTrip.fromJson(Map<String, dynamic> json) {
    return PlannerSavedTrip(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? 'Saved Trip',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      itinerary: PlannerItinerary.fromJson(
        (json['itinerary'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
