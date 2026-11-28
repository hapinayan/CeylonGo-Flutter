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

class TourGuideDetailScreen extends StatefulWidget {
  final int listingId;
  final TourGuideListingModel? initialListing;
  final DiscoveryService? discoveryService;
  final BookingPaymentService? bookingService;
  final SecureStorageService? storageService;

  const TourGuideDetailScreen({
    super.key,
    required this.listingId,
    this.initialListing,
    this.discoveryService,
    this.bookingService,
    this.storageService,
  });

  @override
  State<TourGuideDetailScreen> createState() => _TourGuideDetailScreenState();
}

class _TourGuideDetailScreenState extends State<TourGuideDetailScreen> {
  late final DiscoveryService _discoveryService;
  late final BookingPaymentService _bookingService;
  late final SecureStorageService _storage;

  TourGuideListingModel? _guide;
  bool _isLoading = true;
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  bool _isWishlisted = false;

  String? _errorMessage;
  String? _slotError;
  String? _bookingError;

  int? _selectedPackageId;
  DateTime? _selectedDate;
  int _participants = 1;
  List<GuideSlotModel> _slots = [];
  int? _selectedSlotId;

  String? _pendingRequestKey;
  String? _pendingKeySignature;

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _bookingService = widget.bookingService ?? BookingPaymentService();
    _storage = widget.storageService ?? SecureStorageService();
    _guide = widget.initialListing;
    if (_guide != null && _guide!.packages.isNotEmpty) {
      _selectedPackageId = _guide!.packages.first.id;
    }
    _loadDetail();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = _guide == null;
      _errorMessage = null;
    });

    try {
      final detail = await _discoveryService.getTourGuideDetail(widget.listingId);
      bool saved = false;
      if (await _storage.hasToken()) {
        try {
          final wl = await _discoveryService.getTourGuideWishlist();
          saved = wl.any((e) => e.id == widget.listingId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _guide = detail;
        _isWishlisted = saved;
        _isLoading = false;
        if (detail.packages.isNotEmpty &&
            !detail.packages.any((p) => p.id == _selectedPackageId)) {
          _selectedPackageId = detail.packages.first.id;
        }
      });
      if (_selectedPackageId != null) {
        await _loadSlots();
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load tour guide details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedPackageId == null) return;
    setState(() {
      _isLoadingSlots = true;
      _slotError = null;
    });
    try {
      final slots = await _discoveryService.getTourGuideAvailability(
        listingId: widget.listingId,
        packageId: _selectedPackageId!,
        date: _selectedDate != null ? _formatDate(_selectedDate!) : null,
        participants: _participants,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _isLoadingSlots = false;
        final avail = slots.where((s) => s.available).toList();
        if (avail.isNotEmpty) {
          if (!avail.any((s) => s.id == _selectedSlotId)) {
            _selectedSlotId = avail.first.id;
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
        _slotError = 'Unable to check guide availability.';
        _slots = [];
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('save tour guides');
      return;
    }
    final next = !_isWishlisted;
    setState(() => _isWishlisted = next);
    try {
      await _discoveryService.setTourGuideWishlist(widget.listingId, save: next);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isWishlisted = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  Future<void> _bookGuide() async {
    if (_isBooking || _selectedSlotId == null) return;
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('book this tour guide');
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
            serviceTitle: _guide?.title ?? 'Tour Guide Booking',
            summarySubtitle:
                '${slot.startsAt.toLocal().toString().substring(0, 16)} • $_participants participant(s)',
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
            'Network error while booking guide. Tap Book Guide again to retry safely.';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Tour Guide Profile')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    if (_errorMessage != null || _guide == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Tour Guide Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                Text(_errorMessage ?? 'Tour guide not found.'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final item = _guide!;
    final selectedPkg = item.packages.where((p) => p.id == _selectedPackageId).firstOrNull;
    final maxPeople = selectedPkg?.maxPeople ?? 10;

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
              height: 210,
              child: CeylonGoNetworkImage(
                imageUrl: item.coverImageUrl,
                fallbackIcon: Icons.person_outline_rounded,
                iconSize: 48,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    '${item.locationLabel} • ${item.yearsOfExperience} yrs exp • ${item.providerName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (item.languages.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.languages
                          .map(
                            (l) => Chip(
                              label: Text(l, style: const TextStyle(fontSize: 12)),
                              backgroundColor: const Color(0xFFFFF7ED),
                              side: const BorderSide(color: Color(0xFFFED7AA)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (item.hasCoordinates ||
                      (selectedPkg?.meetingLatitude != null &&
                          selectedPkg?.meetingLongitude != null)) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        final lat = selectedPkg?.meetingLatitude ?? item.latitude!;
                        final lon = selectedPkg?.meetingLongitude ?? item.longitude!;
                        ArtisanLauncherService.showDirectionsModal(
                          context,
                          title: item.title,
                          latitude: lat,
                          longitude: lon,
                          address: selectedPkg?.meetingPoint,
                          city: item.locationLabel,
                        );
                      },
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Meeting Point Directions'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 16),

                  // Packages & Availability
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
                          'Packages & Availability',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (item.packages.isEmpty)
                          const Text(
                            'No active tour packages published yet.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          )
                        else ...[
                          ...item.packages.map((pkg) {
                            final selected = pkg.id == _selectedPackageId;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPackageId = pkg.id;
                                  if (_participants > pkg.maxPeople) {
                                    _participants = pkg.maxPeople;
                                  }
                                });
                                _loadSlots();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF0A4DF5)
                                        : AppTheme.borderSlate,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pkg.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryNavy,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${formatLkrAmount(pkg.price)} (${pkg.pricingType})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accentOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pkg.durationHours}h • Max ${pkg.maxPeople} people • Meet: ${pkg.meetingPoint}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
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
                                        ? 'Filter by Date (All)'
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
                                'Participants (Max $maxPeople)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _participants > 1
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
                                    onPressed: _participants < maxPeople
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
                          const SizedBox(height: 8),
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
                              'No open guide slots available for this package.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            )
                          else
                            ..._slots.map((slot) {
                              final selected = _selectedSlotId == slot.id;
                              final startLocal = slot.startsAt.toLocal();
                              final endLocal = slot.endsAt.toLocal();
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
                                        color: slot.available
                                            ? const Color(0xFF0A4DF5)
                                            : AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${startLocal.toString().substring(0, 16)} → ${endLocal.toString().substring(11, 16)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryNavy,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        slot.available
                                            ? formatLkrAmount(slot.totalAmount)
                                            : 'Busy',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: slot.available
                                              ? AppTheme.accentOrange
                                              : AppTheme.errorRed,
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
                              key: const Key('guide_book_btn'),
                              onPressed: (_isBooking || _selectedSlotId == null)
                                  ? null
                                  : _bookGuide,
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
                                      'Request Guide Booking',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
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
