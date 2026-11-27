import 'package:flutter/material.dart';

import 'ai_planner_api_models.dart';

enum ChatSender { user, assistant }

class ItineraryDayItem {
  final String dayLabel;
  final String title;
  final String description;
  final String imageUrl;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const ItineraryDayItem({
    required this.dayLabel,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.fallbackColor,
  });
}

class TravelPlanCardData {
  final String title;
  final String categoryBadge;
  final List<ItineraryDayItem> days;

  const TravelPlanCardData({
    required this.title,
    required this.categoryBadge,
    required this.days,
  });
}

class AiChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final String timestamp;
  final TravelPlanCardData? travelPlan;
  final bool isError;
  final int? turnId;
  final PlannerProposal? proposal;
  final List<PlannerListingResult> listings;
  final List<PlannerQuote> quotes;

  const AiChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.travelPlan,
    this.isError = false,
    this.turnId,
    this.proposal,
    this.listings = const [],
    this.quotes = const [],
  });
}

