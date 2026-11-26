import 'package:flutter/material.dart';

import '../models/ai_chat_message.dart';

/// Offline Demo Mode Service for CeylonGo AI Travel Planner.
/// Provides sample Sri Lankan travel recommendations without calling external AI APIs.
class AiPlannerDemoService {
  static const TravelPlanCardData defaultThreeDayPlan = TravelPlanCardData(
    title: '3-Day Sri Lanka Travel Plan',
    categoryBadge: 'Culture & Nature',
    days: [
      ItineraryDayItem(
        dayLabel: 'Day 1',
        title: 'Day 1 – Sigiriya & Dambulla',
        description: 'Climb Sigiriya Rock, visit Dambulla Cave Temple',
        imageUrl:
            'https://images.unsplash.com/photo-1588598198321-9735fd52455b?w=400',
        fallbackIcon: Icons.landscape_rounded,
        fallbackColor: Color(0xFF0284C7),
      ),
      ItineraryDayItem(
        dayLabel: 'Day 2',
        title: 'Day 2 – Kandy',
        description: 'Temple of the Tooth, Kandy Lake, cultural showcase',
        imageUrl:
            'https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?w=400',
        fallbackIcon: Icons.temple_buddhist_rounded,
        fallbackColor: Color(0xFF2563EB),
      ),
      ItineraryDayItem(
        dayLabel: 'Day 3',
        title: 'Day 3 – Nuwara Eliya',
        description: 'Tea estates, waterfalls, and scenic views',
        imageUrl:
            'https://images.unsplash.com/photo-1546708973-b339540b5162?w=400',
        fallbackIcon: Icons.water_drop_rounded,
        fallbackColor: Color(0xFF10B981),
      ),
    ],
  );

  static List<AiChatMessage> initialConversation() {
    return const [
      AiChatMessage(
        id: 'init_greeting',
        sender: ChatSender.assistant,
        text:
            '👋 Hi! I’m CeylonGo AI Planner.\n\nI can help you plan your Sri Lanka trip, suggest places, create an itinerary, and more.\n\nHow can I help you today?',
        timestamp: '9:30 AM',
      ),
      AiChatMessage(
        id: 'sample_user_1',
        sender: ChatSender.user,
        text: 'Plan a 3-day trip in Sri Lanka for culture and nature.',
        timestamp: '9:31 AM',
      ),
      AiChatMessage(
        id: 'sample_assistant_1',
        sender: ChatSender.assistant,
        text:
            'Sure! Here’s a 3-day travel plan for culture and nature in Sri Lanka:',
        timestamp: '9:31 AM',
        travelPlan: defaultThreeDayPlan,
      ),
    ];
  }

  Future<AiChatMessage> generateDemoReply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 450));

    final lower = prompt.toLowerCase();
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';

    if (lower.contains('place') || lower.contains('idea')) {
      return AiChatMessage(
        id: 'demo_${DateTime.now().microsecondsSinceEpoch}',
        sender: ChatSender.assistant,
        text:
            'Here are top Sri Lanka places to explore (Offline Demo):\n\n• Sigiriya & Dambulla – Ancient rock fortress & cave temples\n• Ella – Nine Arch Bridge & Little Adam’s Peak\n• Galle Fort – Colonial heritage & coastal sunsets\n• Jaffna – Nallur Kovil & northern island culture',
        timestamp: timeStr,
      );
    }

    if (lower.contains('tip') || lower.contains('advice')) {
      return AiChatMessage(
        id: 'demo_${DateTime.now().microsecondsSinceEpoch}',
        sender: ChatSender.assistant,
        text:
            'Sri Lanka Travel Tips (Offline Demo):\n\n• Carry LKR cash for local buses, street food, and artisan markets.\n• Dress modestly when visiting temples (shoulders & knees covered).\n• Book scenic hill-country train seats (Kandy → Ella) in advance.',
        timestamp: timeStr,
      );
    }

    if (lower.contains('customize') || lower.contains('modify')) {
      return AiChatMessage(
        id: 'demo_${DateTime.now().microsecondsSinceEpoch}',
        sender: ChatSender.assistant,
        text:
            'I’d be happy to customize your 3-day plan! Tell me if you want to swap in coastal beaches (Mirissa/Galle), wildlife safaris (Yala/Udawalawe), or add extra days.',
        timestamp: timeStr,
      );
    }

    if (lower.contains('itinerary') || lower.contains('plan')) {
      return AiChatMessage(
        id: 'demo_${DateTime.now().microsecondsSinceEpoch}',
        sender: ChatSender.assistant,
        text:
            'Here is a curated Sri Lanka itinerary suggestion (Offline Demo):',
        timestamp: timeStr,
        travelPlan: defaultThreeDayPlan,
      );
    }

    return AiChatMessage(
      id: 'demo_${DateTime.now().microsecondsSinceEpoch}',
      sender: ChatSender.assistant,
      text:
          'Offline Demo Suggestion: For "$prompt", I recommend combining Cultural Triangle highlights (Sigiriya & Kandy) with hill-country tea estates in Nuwara Eliya or Ella.',
      timestamp: timeStr,
    );
  }
}

