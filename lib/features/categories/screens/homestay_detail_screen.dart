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

class HomestayDetailScreen extends StatefulWidget {
  final int listingId;
  final HomestayListingModel? initialListing;
  final DiscoveryService? discoveryService;
  final BookingPaymentService? bookingService;
  final SecureStorageService? storageService;

  const HomestayDetailScreen({
    super.key,
    required this.listingId,
    this.initialListing,
    this.discoveryService,
    this.bookingService,
    this.storageService,
  });

  @override
  State<HomestayDetailScreen> createState() => _HomestayDetailScreenState();
}

class _HomestayDetailScreenState extends State<HomestayDetailScreen> {
  late final DiscoveryService _discoveryService;
  late final BookingPaymentService _bookingService;
  late final SecureStorageService _storage;

  HomestayListingModel? _listing;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isWishlisted = false;
  bool _isCheckingAvailability = false;
  bool _isBooking = false;
  String? _availabilityError;
  String? _bookingError;

  late DateTime _checkIn;
  late DateTime _checkOut;
  int _guests = 1;
  HomestayQuoteModel? _quote;
  int? _selectedRoomId;

  // Idempotency key preserved across network retries for the same booking parameters
  String? _pendingRequestKey;
  String? _pendingKeySignature;

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _bookingService = widget.bookingService ?? BookingPaymentService();
    _storage = widget.storageService ?? SecureStorageService();

    final now = DateTime.now();
    _checkIn = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _checkOut = _checkIn.add(const Duration(days: 1));
    _listing = widget.initialListing;
    _loadDetail();
  }

  String _formatDateParam(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = _listing == null;
      _errorMessage = null;
    });

    try {
      final detail = await _discoveryService.getHomestayDetail(widget.listingId);
      bool saved = false;
      if (await _storage.hasToken()) {
        try {
          final wishlist = await _discoveryService.getHomestayWishlist();
          saved = wishlist.any((item) => item.id == widget.listingId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _listing = detail;
        _isWishlisted = saved;
        _isLoading = false;
      });
      await _checkAvailability();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load homestay details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _isCheckingAvailability = true;
      _availabilityError = null;
    });
    try {
      final quote = await _discoveryService.checkHomestayAvailability(
        listingId: widget.listingId,
        checkIn: _formatDateParam(_checkIn),
        checkOut: _formatDateParam(_checkOut),
        guests: _guests,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _isCheckingAvailability = false;
        if (quote.availableRooms.isNotEmpty) {
          final stillValid = quote.availableRooms.any((r) => r.id == _selectedRoomId);
          if (!stillValid) {
            _selectedRoomId = quote.availableRooms.first.id;
          }
        } else {
          _selectedRoomId = null;
        }
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingAvailability = false;
        _quote = null;
        _availabilityError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingAvailability = false;
        _quote = null;
        _availabilityError = 'Failed to check room availability.';
      });
    }
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
    );
    if (range == null) return;
    final end = range.end.isAfter(range.start)
        ? range.end
        : range.start.add(const Duration(days: 1));
    setState(() {
      _checkIn = range.start;
      _checkOut = end;
      _bookingError = null;
    });
    await _checkAvailability();
  }

  Future<void> _toggleWishlist() async {
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('save homestays to your wishlist');
      return;
    }
    final next = !_isWishlisted;
    setState(() => _isWishlisted = next);
    try {
      await _discoveryService.setHomestayWishlist(widget.listingId, save: next);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isWishlisted = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  Future<void> _submitBooking() async {
    if (_isBooking || _selectedRoomId == null || _quote == null) return;
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('book this homestay');
      return;
    }

    final selectedRoom = _quote!.availableRooms.firstWhere(
      (r) => r.id == _selectedRoomId,
      orElse: () => _quote!.availableRooms.first,
    );
    final nightly = double.tryParse(selectedRoom.nightlyPrice ?? _quote!.nightlyRate) ??
        double.tryParse(_quote!.nightlyRate) ??
        0;
    final expectedTotal = (nightly * _quote!.nights).toStringAsFixed(2);

    final signature =
        '${widget.listingId}|${_formatDateParam(_checkIn)}|${_formatDateParam(_checkOut)}|$_guests|$_selectedRoomId|$expectedTotal';
    if (_pendingKeySignature != signature || _pendingRequestKey == null) {
      _pendingKeySignature = signature;
      _pendingRequestKey = UuidGenerator.v4();
    }

    setState(() {
      _isBooking = true;
      _bookingError = null;
    });

    try {
      final booking = await _bookingService.createHomestayBooking(
        listingId: widget.listingId,
        checkIn: _formatDateParam(_checkIn),
        checkOut: _formatDateParam(_checkOut),
        guests: _guests,
        roomId: _selectedRoomId!,
        requestKey: _pendingRequestKey!,
        expectedTotal: expectedTotal,
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
            serviceTitle: _listing?.title ?? 'Homestay Booking',
            summarySubtitle:
                '${_formatDateParam(_checkIn)} to ${_formatDateParam(_checkOut)} • ${_quote!.nights} night(s) • $_guests guest(s)',
          ),
        ),
      );
      await _checkAvailability();
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
            'Network error while creating booking. Tap Book Stay again to retry safely.';
      });
    }
  }

  void _promptSignIn(String action) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In Required'),
        content: Text('Please sign in with your traveler account to $action.'),
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
        appBar: AppBar(title: const Text('Homestay Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    if (_errorMessage != null || _listing == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Homestay Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Homestay not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadDetail,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = _listing!;
    final quote = _quote;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('homestay_wishlist_btn'),
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
                fallbackIcon: Icons.home_outlined,
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
                      if (item.propertyType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.propertyType!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A4DF5),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${formatLkrAmount(item.price)} / night',
                        style: const TextStyle(
                          fontSize: 18,
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
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.locationLabel} • Hosted by ${item.hostName.isNotEmpty ? item.hostName : 'Local Host'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.hasCoordinates) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => ArtisanLauncherService.showDirectionsModal(
                        context,
                        title: item.title,
                        latitude: item.latitude!,
                        longitude: item.longitude!,
                        city: item.locationLabel,
                      ),
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Directions & Map Coordinates'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (item.description.isNotEmpty) ...[
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (item.amenities.isNotEmpty) ...[
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.amenities
                          .map(
                            (a) => Chip(
                              label: Text(a, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFDBEAFE)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Availability & Booking Panel
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
                          'Check Availability & Book',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('homestay_dates_btn'),
                          onPressed: _pickDates,
                          icon: const Icon(Icons.date_range_outlined, size: 18),
                          label: Text(
                            '${_formatDateParam(_checkIn)} → ${_formatDateParam(_checkOut)}',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Guests',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _guests > 1
                                      ? () {
                                          setState(() => _guests--);
                                          _checkAvailability();
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$_guests',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _guests < 20
                                      ? () {
                                          setState(() => _guests++);
                                          _checkAvailability();
                                        }
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isCheckingAvailability)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          )
                        else if (_availabilityError != null)
                          Text(
                            _availabilityError!,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 13,
                            ),
                          )
                        else if (quote != null) ...[
                          if (quote.availableRooms.isEmpty)
                            const Text(
                              'No rooms available for the selected dates and guest count. Try different dates.',
                              style: TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 13,
                              ),
                            )
                          else ...[
                            const Text(
                              'Select Available Room',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...quote.availableRooms.map((room) {
                              final rate = room.nightlyPrice ?? quote.nightlyRate;
                              final total =
                                  (double.tryParse(rate) ?? 0) * quote.nights;
                              final selected = _selectedRoomId == room.id;
                              return InkWell(
                                onTap: () =>
                                    setState(() => _selectedRoomId = room.id),
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
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: selected
                                            ? const Color(0xFF0A4DF5)
                                            : AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              room.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryNavy,
                                              ),
                                            ),
                                            Text(
                                              'Up to ${room.capacity} guests • ${quote.nights} night(s)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatLkrAmount(total),
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
                          ],
                        ],
                        if (_bookingError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _bookingError!,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            key: const Key('homestay_book_btn'),
                            onPressed: (_isBooking ||
                                    _selectedRoomId == null ||
                                    _isCheckingAvailability)
                                ? null
                                : _submitBooking,
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
                                    'Request Homestay Booking',
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
