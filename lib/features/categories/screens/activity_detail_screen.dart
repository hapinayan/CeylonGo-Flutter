import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../core/widgets/ceylongo_network_image.dart';
import '../../artisan/services/artisan_launcher_service.dart';
import '../../auth/models/api_error.dart';
import '../../bookings/services/booking_payment_service.dart';
import '../../bookings/widgets/booking_payment_sheet.dart';
import '../models/discovery_models.dart';
import '../services/discovery_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int listingId;
  final ActivityListingModel? initialListing;
  final DiscoveryService? discoveryService;
  final BookingPaymentService? bookingService;
  final SecureStorageService? storageService;

  const ActivityDetailScreen({
    super.key,
    required this.listingId,
    this.initialListing,
    this.discoveryService,
    this.bookingService,
    this.storageService,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late final DiscoveryService _discoveryService;
  late final BookingPaymentService _bookingService;
  late final SecureStorageService _storage;

  ActivityListingModel? _listing;
  List<ActivitySlotModel> _slots = [];
  bool _isLoading = true;
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  bool _isWishlisted = false;

  String? _errorMessage;
  String? _slotError;
  String? _bookingError;

  DateTime? _selectedDate;
  late int _participants;
  int? _selectedSlotId;

  String? _pendingRequestKey;
  String? _pendingKeySignature;

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _bookingService = widget.bookingService ?? BookingPaymentService();
    _storage = widget.storageService ?? SecureStorageService();
    _listing = widget.initialListing;
    _participants = _listing?.minParticipants ?? 1;
    _loadDetail();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = _listing == null;
      _errorMessage = null;
    });
    try {
      final detail = await _discoveryService.getActivityDetail(widget.listingId);
      bool saved = false;
      if (await _storage.hasToken()) {
        try {
          final wl = await _discoveryService.getActivityWishlist();
          saved = wl.any((e) => e.id == widget.listingId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _listing = detail;
        if (_participants < detail.minParticipants) {
          _participants = detail.minParticipants;
        } else if (_participants > detail.maxParticipants) {
          _participants = detail.maxParticipants;
        }
        _isWishlisted = saved;
        _isLoading = false;
      });
      await _loadSlots();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load activity details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _slotError = null;
    });
    try {
      final slots = await _discoveryService.getActivityAvailability(
        listingId: widget.listingId,
        date: _selectedDate != null ? _formatDate(_selectedDate!) : null,
        participants: _participants,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _isLoadingSlots = false;
        final availableSlots = slots.where((s) => s.available).toList();
        if (availableSlots.isNotEmpty) {
          if (!availableSlots.any((s) => s.id == _selectedSlotId)) {
            _selectedSlotId = availableSlots.first.id;
          }
        } else {
          _selectedSlotId = null;
        }
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
        _slotError = e.message;
        _slots = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
        _slotError = 'Unable to load activity slots.';
        _slots = [];
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('save activities');
      return;
    }
    final next = !_isWishlisted;
    setState(() => _isWishlisted = next);
    try {
      await _discoveryService.setActivityWishlist(widget.listingId, save: next);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isWishlisted = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  Future<void> _bookActivity() async {
    if (_isBooking || _selectedSlotId == null) return;
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('book this activity');
      return;
    }

    final slot = _slots.firstWhere((s) => s.id == _selectedSlotId);
    final signature =
        '${widget.listingId}|${slot.id}|$_participants|${slot.totalAmount}';
    if (_pendingKeySignature != signature || _pendingRequestKey == null) {
      _pendingKeySignature = signature;
      _pendingRequestKey = UuidGenerator.v4();
    }

    setState(() {
      _isBooking = true;
      _bookingError = null;
    });

    try {
      final booking = await _bookingService.createBooking(
        listingId: widget.listingId,
        startsAt: slot.startsAt,
        endsAt: slot.endsAt,
        quantity: _participants,
        requestKey: _pendingRequestKey!,
        slotId: slot.id,
        expectedTotal: slot.totalAmount,
      );

      _pendingKeySignature = null;
      _pendingRequestKey = null;

      if (!mounted) return;
      setState(() => _isBooking = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPaymentScreen(
            booking: booking,
            serviceTitle: _listing?.title ?? 'Activity Booking',
            summarySubtitle:
                '${slot.date} • $_participants participant(s)',
          ),
        ),
      );
      await _loadSlots();
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.statusCode >= 400 && e.statusCode < 500) {
        _pendingKeySignature = null;
        _pendingRequestKey = null;
      }
      setState(() {
        _isBooking = false;
        _bookingError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _bookingError =
            'Network error while booking. Tap Book Activity again to retry safely.';
      });
    }
  }

  void _promptSignIn(String action) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In Required'),
        content: Text('Please sign in to $action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  String _formatTimeRange(ActivitySlotModel s) {
    final startLocal = s.startsAt.toLocal();
    final endLocal = s.endsAt.toLocal();
    String hhmm(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${s.date} • ${hhmm(startLocal)} - ${hhmm(endLocal)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Activity Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    if (_errorMessage != null || _listing == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Activity Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                Text(_errorMessage ?? 'Activity not found.'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final item = _listing!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: _isWishlisted ? AppTheme.errorRed : AppTheme.primaryNavy,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 220,
              child: CeylonGoNetworkImage(
                imageUrl: item.coverImageUrl,
                fallbackIcon: Icons.terrain_rounded,
                iconSize: 48,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatLkrAmount(item.pricePerParticipant)} / person',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.locationLabel} • ${item.durationMinutes} min • ${item.providerName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (item.meetingPoint.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Meeting Point: ${item.meetingPoint}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (item.hasCoordinates) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => ArtisanLauncherService.showDirectionsModal(
                        context,
                        title: item.title,
                        latitude: item.latitude!,
                        longitude: item.longitude!,
                        address: item.meetingPoint,
                        city: item.locationLabel,
                      ),
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Directions & Map Coordinates'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                  if (item.safetyInstructions != null &&
                      item.safetyInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Safety: ${item.safetyInstructions}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Slot & Participant Selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Select Date, Participants & Time Slot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: now,
                                    lastDate: now.add(const Duration(days: 365)),
                                    initialDate: _selectedDate ?? now,
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                    _loadSlots();
                                  }
                                },
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  _selectedDate == null
                                      ? 'All Upcoming Dates'
                                      : _formatDate(_selectedDate!),
                                ),
                              ),
                            ),
                            if (_selectedDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _selectedDate = null);
                                  _loadSlots();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Participants (${item.minParticipants}–${item.maxParticipants})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _participants > item.minParticipants
                                      ? () {
                                          setState(() => _participants--);
                                          _loadSlots();
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$_participants',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _participants < item.maxParticipants
                                      ? () {
                                          setState(() => _participants++);
                                          _loadSlots();
                                        }
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingSlots)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          )
                        else if (_slotError != null)
                          Text(
                            _slotError!,
                            style: const TextStyle(color: AppTheme.errorRed),
                          )
                        else if (_slots.isEmpty)
                          const Text(
                            'No scheduled slots available for this selection.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          )
                        else
                          ..._slots.map((slot) {
                            final selected = _selectedSlotId == slot.id;
                            return InkWell(
                              onTap: slot.available
                                  ? () => setState(() => _selectedSlotId = slot.id)
                                  : null,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: !slot.available
                                      ? const Color(0xFFF8FAFC)
                                      : (selected
                                          ? const Color(0xFFEFF6FF)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF0A4DF5)
                                        : AppTheme.borderSlate,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: !slot.available
                                          ? AppTheme.textMuted
                                          : (selected
                                              ? const Color(0xFF0A4DF5)
                                              : AppTheme.textMuted),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatTimeRange(slot),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryNavy,
                                            ),
                                          ),
                                          Text(
                                            slot.available
                                                ? '${slot.remainingCapacity} spot(s) left'
                                                : 'Unavailable / Full',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: slot.available
                                                  ? AppTheme.textSecondary
                                                  : AppTheme.errorRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatLkrAmount(slot.totalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        if (_bookingError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _bookingError!,
                            style: const TextStyle(color: AppTheme.errorRed),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            key: const Key('activity_book_btn'),
                            onPressed: (_isBooking || _selectedSlotId == null)
                                ? null
                                : _bookActivity,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.white,
                            ),
                            child: _isBooking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Request Activity Booking',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
