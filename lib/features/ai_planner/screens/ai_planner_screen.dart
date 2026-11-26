import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/widgets/home_bottom_navigation_bar.dart';
import '../models/ai_chat_message.dart';
import '../services/ai_planner_demo_service.dart';
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

/// CeylonGo AI Travel Planner Chatbot Screen (Offline Demo Mode)
class AiPlannerScreen extends StatefulWidget {
  final AiPlannerDemoService? demoService;
  final bool showBottomNav;

  const AiPlannerScreen({
    super.key,
    this.demoService,
    this.showBottomNav = true,
  });

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  late final AiPlannerDemoService _demoService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<AiChatMessage> _messages;
  final Set<String> _savedPlanMessageIds = {};
  bool _isSending = false;
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
    _messages = List.of(AiPlannerDemoService.initialConversation());
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
      final reply = await _demoService.generateDemoReply(text);
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(reply);
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

  void _toggleSavePlan(AiChatMessage message) {
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

  void _showHistorySheet() {
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
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksSheet() {
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
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
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
                    // Scrollable Conversation
                    Expanded(
                      child: ListView.builder(
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
                        _sendMessage('Customize my 3-day Sri Lanka travel plan'),
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
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Attachments are not supported in offline demo mode.',
                    ),
                    backgroundColor: AppTheme.primaryNavy,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(
                Icons.attach_file_rounded,
                color: Color(0xFF64748B),
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

