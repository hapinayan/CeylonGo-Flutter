import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../../bookings/services/booking_payment_service.dart';
import '../../bookings/widgets/booking_payment_sheet.dart';
import '../../home/widgets/home_bottom_navigation_bar.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_planner_api_models.dart';
import '../services/ai_planner_demo_service.dart';
import '../services/ai_planner_service.dart';
import '../widgets/ai_planner_header.dart';
import '../widgets/ai_travel_plan_card.dart';

class _SuggestionChipData {
  final String label;
  final IconData icon;
  final String prompt;
  final String keyName;

  const _SuggestionChipData({
    required this.label,
    required this.icon,
    required this.prompt,
    required this.keyName,
  });
}

/// CeylonGo AI Travel Planner Screen
/// Connects to FastAPI AI Planner conversations, itineraries, saved trips,
/// quotes and booking confirmation (with explicit demo mode fallback).
class AiPlannerScreen extends StatefulWidget {
  final AiPlannerDemoService? demoService;
  final AiPlannerService? plannerService;
  final SecureStorageService? storageService;
  final BookingPaymentService? bookingService;
  final bool showBottomNav;

  const AiPlannerScreen({
    super.key,
    this.demoService,
    this.plannerService,
    this.storageService,
    this.bookingService,
    this.showBottomNav = true,
  });

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  late final AiPlannerDemoService _demoService;
  late final AiPlannerService _plannerService;
  late final SecureStorageService _storageService;
  late final BookingPaymentService _bookingService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<AiChatMessage> _messages;
  final Set<String> _savedPlanMessageIds = {};
  final Map<int, int> _savedTripIdByTurnId = {};
  List<PlannerThread> _threads = [];
  List<PlannerSavedTrip> _savedTrips = [];
  int? _activeThreadId;
  bool _isInitialLoading = false;
  bool _isSending = false;
  bool _isAuthenticated = false;
  String? _lastFailedPrompt;

  static const Color _royalBlue = Color(0xFF0A4DF5);

  static const List<_SuggestionChipData> _suggestions = [
    _SuggestionChipData(
      label: 'Plan a trip',
      icon: Icons.map_outlined,
      prompt: 'Plan a 3-day trip in Sri Lanka for culture and nature.',
      keyName: 'ai_chip_plan_trip',
    ),
    _SuggestionChipData(
      label: 'Place ideas',
      icon: Icons.place_outlined,
      prompt: 'Suggest top place ideas to visit in Sri Lanka.',
      keyName: 'ai_chip_place_ideas',
    ),
    _SuggestionChipData(
      label: 'Itinerary',
      icon: Icons.event_note_outlined,
      prompt: 'Create a cultural and nature itinerary in Sri Lanka.',
      keyName: 'ai_chip_itinerary',
    ),
    _SuggestionChipData(
      label: 'Travel tips',
      icon: Icons.lightbulb_outline_rounded,
      prompt: 'Share essential travel tips for Sri Lanka.',
      keyName: 'ai_chip_travel_tips',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _demoService = widget.demoService ?? AiPlannerDemoService();
    _plannerService = widget.plannerService ?? AiPlannerService();
    _storageService = widget.storageService ?? SecureStorageService();
    _bookingService = widget.bookingService ?? BookingPaymentService();

    if (ArtisanDemoService.isDemoMode) {
      _isAuthenticated = true;
      _messages = List.of(AiPlannerDemoService.initialConversation());
    } else {
      _messages = [
        AiChatMessage(
          id: 'welcome_live',
          sender: ChatSender.assistant,
          text:
              'Ayubowan! I am your CeylonGo AI Travel Planner. Tell me your destination, days, budget, or interests in Sri Lanka and I will build a tailored plan with real local listings and booking quotes.',
          timestamp: _currentTimeLabel(),
        ),
      ];
      _initializeLivePlanner();
    }
  }

  Future<void> _initializeLivePlanner() async {
    setState(() => _isInitialLoading = true);
    try {
      final hasToken = await _storageService.hasToken();
      if (!hasToken) {
        if (!mounted) return;
        setState(() {
          _isAuthenticated = false;
          _isInitialLoading = false;
        });
        return;
      }

      _isAuthenticated = true;
      final results = await Future.wait([
        _plannerService.getConversations().catchError((_) => <PlannerThread>[]),
        _plannerService.getSavedTrips().catchError((_) => <PlannerSavedTrip>[]),
      ]);
      if (!mounted) return;
      final threads = results[0] as List<PlannerThread>;
      final trips = results[1] as List<PlannerSavedTrip>;

      setState(() {
        _threads = threads;
        _savedTrips = trips;
      });

      if (threads.isNotEmpty) {
        await _loadThread(threads.first.id);
      } else if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadThread(int threadId) async {
    setState(() {
      _activeThreadId = threadId;
      _isInitialLoading = true;
    });
    try {
      final turns = await _plannerService.getMessages(threadId);
      if (!mounted) return;
      // Backend returns newest-first -> reverse to chronological order
      final ordered = turns.reversed.toList();
      final loadedMessages = <AiChatMessage>[
        if (ordered.isEmpty)
          AiChatMessage(
            id: 'thread_empty_$threadId',
            sender: ChatSender.assistant,
            text:
                'Conversation ready. Ask about destinations, homestays, activities, guides, or rentals in Sri Lanka.',
            timestamp: _currentTimeLabel(),
          ),
      ];
      for (final turn in ordered) {
        loadedMessages.add(
          AiChatMessage(
            id: 'u_${turn.id}',
            sender: ChatSender.user,
            text: turn.userMessage,
            timestamp: _formatTime(turn.createdAt),
          ),
        );
        loadedMessages.add(
          AiChatMessage(
            id: 'a_${turn.id}',
            sender: ChatSender.assistant,
            text: turn.assistantMessage,
            timestamp: _formatTime(turn.createdAt),
            travelPlan: turn.itinerary?.toCardData(),
            turnId: turn.id,
            proposal: turn.proposal,
            listings: turn.listings,
            quotes: turn.quotes,
          ),
        );
      }
      setState(() {
        _messages = loadedMessages;
        _isInitialLoading = false;
      });
      _scrollToBottom();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isInitialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$h12:$m $period';
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _currentTimeLabel() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;

    if (!ArtisanDemoService.isDemoMode) {
      final hasToken = await _storageService.hasToken();
      if (!hasToken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to chat with the AI Planner.')),
          );
        }
        return;
      }
    }

    _inputController.clear();
    setState(() {
      _lastFailedPrompt = null;
      _isSending = true;
      _messages.add(
        AiChatMessage(
          id: 'user_${DateTime.now().microsecondsSinceEpoch}',
          sender: ChatSender.user,
          text: text,
          timestamp: _currentTimeLabel(),
        ),
      );
    });
    _scrollToBottom();

    try {
      if (ArtisanDemoService.isDemoMode) {
        final reply = await _demoService.generateDemoReply(text);
        if (!mounted) return;
        setState(() {
          _isSending = false;
          _messages.add(reply);
        });
        _scrollToBottom();
        return;
      }

      if (_activeThreadId == null) {
        final shortTitle =
            text.length > 40 ? '${text.substring(0, 37)}...' : text;
        final created = await _plannerService.createConversation(title: shortTitle);
        _activeThreadId = created.id;
        _threads = [created, ..._threads];
      }

      final turn = await _plannerService.sendMessage(_activeThreadId!, text: text);
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(
          AiChatMessage(
            id: 'a_${turn.id}',
            sender: ChatSender.assistant,
            text: turn.assistantMessage,
            timestamp: _formatTime(turn.createdAt),
            travelPlan: turn.itinerary?.toCardData(),
            turnId: turn.id,
            proposal: turn.proposal,
            listings: turn.listings,
            quotes: turn.quotes,
          ),
        );
      });
      _scrollToBottom();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _lastFailedPrompt = text;
        _messages.add(
          AiChatMessage(
            id: 'err_${DateTime.now().microsecondsSinceEpoch}',
            sender: ChatSender.assistant,
            text: e.message,
            timestamp: _currentTimeLabel(),
            isError: true,
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _lastFailedPrompt = text;
        _messages.add(
          AiChatMessage(
            id: 'err_${DateTime.now().microsecondsSinceEpoch}',
            sender: ChatSender.assistant,
            text: 'Unable to generate a response right now. Please try again.',
            timestamp: _currentTimeLabel(),
            isError: true,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _toggleSavePlan(AiChatMessage message) async {
    if (ArtisanDemoService.isDemoMode) {
      setState(() {
        if (_savedPlanMessageIds.contains(message.id)) {
          _savedPlanMessageIds.remove(message.id);
        } else {
          _savedPlanMessageIds.add(message.id);
        }
      });
      final isNowSaved = _savedPlanMessageIds.contains(message.id);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowSaved
                ? 'Plan saved to local session bookmarks (Offline Demo).'
                : 'Removed plan from local session bookmarks.',
          ),
          backgroundColor: AppTheme.primaryNavy,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final turnId = message.turnId;
    final plan = message.travelPlan;
    if (turnId == null || plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only AI conversation turns can be saved as trips.')),
      );
      return;
    }

    try {
      if (_savedPlanMessageIds.contains(message.id)) {
        final tripId = _savedTripIdByTurnId[turnId];
        if (tripId != null) {
          await _plannerService.deleteSavedTrip(tripId);
        }
        if (!mounted) return;
        setState(() {
          _savedPlanMessageIds.remove(message.id);
          _savedTrips.removeWhere((t) => t.id == tripId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed trip from Saved Trips.')),
        );
      } else {
        final saved = await _plannerService.saveTrip(
          title: plan.title,
          turnId: turnId,
        );
        if (!mounted) return;
        setState(() {
          _savedPlanMessageIds.add(message.id);
          _savedTripIdByTurnId[turnId] = saved.id;
          _savedTrips = [saved, ..._savedTrips];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip saved to your CeylonGo account!')),
        );
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openBookingConfirmation(PlannerProposal proposal) async {
    bool licenseConfirmed = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Confirm AI Booking Quote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proposal.quote.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('Category: ${proposal.quote.category}'),
              Text('Quantity: ${proposal.quote.quantity}'),
              Text(
                'Total: LKR ${proposal.quote.totalLkr}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              if (proposal.quote.motorcycleLicenseRequired) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: licenseConfirmed,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I confirm a valid motorcycle driving license.',
                    style: TextStyle(fontSize: 13),
                  ),
                  onChanged: (v) =>
                      setDialogState(() => licenseConfirmed = v ?? false),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (proposal.quote.motorcycleLicenseRequired && !licenseConfirmed)
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Pay'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      final booking = await _plannerService.confirmBooking(
        confirmationToken: proposal.confirmationToken,
        motorcycleLicenseConfirmed: licenseConfirmed,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPaymentScreen(
            booking: booking,
            serviceTitle: proposal.quote.title,
            summarySubtitle: 'AI Planned Booking • LKR ${booking.totalAmount}',
            service: _bookingService,
          ),
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmation failed.')),
      );
    }
  }

  Future<void> _requestListingQuote(PlannerListingResult listing) async {
    try {
      final start = DateTime.now().add(const Duration(days: 2));
      final end = start.add(const Duration(days: 1));
      final proposal = await _plannerService.createBookingQuote(
        listingId: listing.listingId,
        quantity: 1,
        startsAt: start,
        endsAt: end,
        roomId: listing.category == 'homestay' && listing.options.isNotEmpty
            ? listing.options.first.id
            : null,
        slotId: listing.category == 'activity' && listing.options.isNotEmpty
            ? listing.options.first.id
            : null,
        packageId: listing.category == 'tour_guide' && listing.options.isNotEmpty
            ? listing.options.first.id
            : null,
      );
      if (!mounted) return;
      await _openBookingConfirmation(proposal);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate quote for this listing.')),
      );
    }
  }

  void _sharePlan(TravelPlanCardData plan) {
    final summary = StringBuffer('${plan.title} (${plan.categoryBadge})\n');
    for (final day in plan.days) {
      summary.writeln('• ${day.title}: ${day.description}');
    }
    Clipboard.setData(ClipboardData(text: summary.toString().trim()));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Itinerary copied to clipboard for sharing.'),
        backgroundColor: AppTheme.primaryNavy,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showHistorySheet() async {
    if (ArtisanDemoService.isDemoMode) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chat History (Offline Demo)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_messages.length} messages in current session.',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    try {
      final threads = await _plannerService.getConversations();
      if (mounted) setState(() => _threads = threads);
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Planner Conversations',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _activeThreadId = null;
                      _messages = [
                        AiChatMessage(
                          id: 'new_thread_${DateTime.now().millisecondsSinceEpoch}',
                          sender: ChatSender.assistant,
                          text:
                              'Started a new trip planning conversation. Where in Sri Lanka would you like to travel?',
                          timestamp: _currentTimeLabel(),
                        ),
                      ];
                    });
                  },
                  icon: const Icon(Icons.add_comment_outlined, size: 17),
                  label: const Text('New Chat'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_threads.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No saved conversations yet.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _threads.length,
                  itemBuilder: (_, idx) {
                    final t = _threads[idx];
                    return ListTile(
                      selected: t.id == _activeThreadId,
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 19),
                        onPressed: () async {
                          await _plannerService.deleteConversation(t.id);
                          Navigator.pop(ctx);
                          if (_activeThreadId == t.id) {
                            _activeThreadId = null;
                          }
                          _initializeLivePlanner();
                        },
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _loadThread(t.id);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBookmarksSheet() async {
    if (ArtisanDemoService.isDemoMode) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Plans (Local Session)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _savedPlanMessageIds.isEmpty
                    ? 'No plans saved yet. Tap "Save Plan" on an itinerary to bookmark it locally.'
                    : '${_savedPlanMessageIds.length} travel plan(s) bookmarked in this session.',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    try {
      final trips = await _plannerService.getSavedTrips();
      if (mounted) setState(() => _savedTrips = trips);
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Saved Trips',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 10),
            if (_savedTrips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No trips saved yet. Tap "Save Plan" on a generated itinerary.',
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _savedTrips.length,
                  itemBuilder: (_, idx) {
                    final trip = _savedTrips[idx];
                    return ListTile(
                      leading: const Icon(Icons.bookmark_rounded, color: AppTheme.primaryNavy),
                      title: Text(trip.title),
                      subtitle: Text(
                        '${trip.itinerary.days.length} day(s) • Est. LKR ${trip.itinerary.estimatedTotalLkr}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                        onPressed: () async {
                          await _plannerService.deleteSavedTrip(trip.id);
                          Navigator.pop(ctx);
                          setState(() {
                            _savedTrips.removeWhere((t) => t.id == trip.id);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQuickItineraryDialog() async {
    if (ArtisanDemoService.isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attachments are not supported in offline demo mode.'),
          backgroundColor: AppTheme.primaryNavy,
        ),
      );
      return;
    }

    final destCtrl = TextEditingController(text: 'Kandy & Ella');
    int days = 3;
    String budget = 'moderate';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Quick Itinerary Generator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: days,
                decoration: const InputDecoration(labelText: 'Duration (Days)'),
                items: [1, 2, 3, 5, 7]
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d Days')))
                    .toList(),
                onChanged: (v) => setDialogState(() => days = v ?? 3),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: budget,
                decoration: const InputDecoration(labelText: 'Budget Level'),
                items: const ['budget', 'moderate', 'luxury']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setDialogState(() => budget = v ?? 'moderate'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
    if (result != true || destCtrl.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final generated = await _plannerService.generateItinerary(
        destination: destCtrl.text.trim(),
        durationDays: days,
        budgetLevel: budget,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(
          AiChatMessage(
            id: 'itin_${DateTime.now().microsecondsSinceEpoch}',
            sender: ChatSender.assistant,
            text: generated.summaryText,
            timestamp: _currentTimeLabel(),
            travelPlan: generated.card,
          ),
        );
      });
      _scrollToBottom();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _onBottomNavSelected(int index) {
    if (index == 2) return;
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/artisan');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/community');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1 & 2. Upper Header + AI Travel Planner Title
            AiPlannerHeader(
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                }
              },
              onHistoryTap: _showHistorySheet,
              onBookmarkTap: _showBookmarksSheet,
              hasSavedPlans: _savedPlanMessageIds.isNotEmpty,
            ),

            // 3-8. Large Rounded White Chat Container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Auth banner if not signed in (live mode)
                    if (!ArtisanDemoService.isDemoMode && !_isAuthenticated)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        color: const Color(0xFFFFF7ED),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Sign in to save trips, chat with AI Planner, and confirm bookings.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ),
                    // Scrollable Conversation
                    Expanded(
                      child: _isInitialLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                        itemCount: _messages.length + 1 + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildDateSeparator();
                          }

                          final msgIndex = index - 1;
                          if (msgIndex >= _messages.length) {
                            return _buildTypingIndicator();
                          }

                          final message = _messages[msgIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMessageBubble(message),
                              if (msgIndex == 0) _buildQuickSuggestionChips(),
                            ],
                          );
                        },
                      ),
                    ),

                    // 9. Chat Message Input Composer
                    _buildMessageComposer(),
                  ],
                ),
              ),
            ),
          ],
        ),
        // 10. Shared Fixed Bottom Navigation Bar (AI Planner active)
        bottomNavigationBar: widget.showBottomNav
            ? HomeBottomNavigationBar(
                currentIndex: 2,
                onTabSelected: _onBottomNavSelected,
              )
            : null,
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Today',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSuggestionChips() {
    return Padding(
      padding: const EdgeInsets.only(left: 38, bottom: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_suggestions.length, (i) {
            final chip = _suggestions[i];
            return Padding(
              padding: EdgeInsets.only(
                right: i == _suggestions.length - 1 ? 0 : 8,
              ),
              child: OutlinedButton.icon(
                key: Key(chip.keyName),
                onPressed: () => _sendMessage(chip.prompt),
                icon: Icon(chip.icon, size: 14, color: _royalBlue),
                label: Text(
                  chip.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFDBEAFE), width: 1.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    final isUser = message.sender == ChatSender.user;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 265),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _royalBlue,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _royalBlue.withAlpha(35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.timestamp,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(
                Icons.person_rounded,
                size: 17,
                color: AppTheme.primaryNavy,
              ),
            ),
          ],
        ),
      );
    }

    // Assistant Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFF0A4DF5),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFEFF6FF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: message.isError
                              ? AppTheme.errorRed
                              : const Color(0xFF0F172A),
                          height: 1.4,
                        ),
                      ),
                      if (message.isError && _lastFailedPrompt != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _sendMessage(_lastFailedPrompt!),
                          icon: const Icon(Icons.refresh_rounded, size: 15),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (message.travelPlan != null) ...[
                  const SizedBox(height: 10),
                  AiTravelPlanCard(
                    plan: message.travelPlan!,
                    isSaved: _savedPlanMessageIds.contains(message.id),
                    onSavePlan: () => _toggleSavePlan(message),
                    onSharePlan: () => _sharePlan(message.travelPlan!),
                    onCustomizePlan: () =>
                        _sendMessage('Customize my Sri Lanka travel plan'),
                  ),
                ],
                if (message.proposal != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openBookingConfirmation(message.proposal!),
                    icon: const Icon(Icons.check_circle_outline, size: 17),
                    label: Text(
                      'Book Quote: ${message.proposal!.quote.title} (LKR ${message.proposal!.quote.totalLkr})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ] else if (message.listings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.listings.take(4).map((l) {
                      return ActionChip(
                        avatar: const Icon(Icons.request_quote_outlined, size: 15),
                        label: Text(
                          'Quote: ${l.title}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => _requestListingQuote(l),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  message.timestamp,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFF0A4DF5),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _royalBlue,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Planning your trip...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              key: const Key('ai_planner_attach_btn'),
              onPressed: _openQuickItineraryDialog,
              tooltip: 'Quick Itinerary Generator',
              icon: const Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xFF0A4DF5),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Expanded(
              child: TextField(
                key: const Key('ai_planner_input'),
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask anything about your Sri Lanka trip...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              key: const Key('ai_planner_send_btn'),
              onTap: () => _sendMessage(_inputController.text),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _royalBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _royalBlue.withAlpha(65),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

