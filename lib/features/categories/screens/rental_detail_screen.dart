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

class RentalDetailScreen extends StatefulWidget {
  final int vehicleId;
  final RentalVehicleModel? initialVehicle;
  final DiscoveryService? discoveryService;
  final BookingPaymentService? bookingService;
  final SecureStorageService? storageService;

  const RentalDetailScreen({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
    this.discoveryService,
    this.bookingService,
    this.storageService,
  });

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  late final DiscoveryService _discoveryService;
  late final BookingPaymentService _bookingService;
  late final SecureStorageService _storage;

  RentalVehicleModel? _vehicle;
  RentalQuoteModel? _quote;

  bool _isLoading = true;
  bool _isQuoting = false;
  bool _isBooking = false;
  bool _isWishlisted = false;

  String? _errorMessage;
  String? _quoteError;
  String? _bookingError;

  late DateTime _pickupAt;
  late DateTime _returnAt;
  int _quantity = 1;

  bool _licenseConfirmed = false;
  DateTime? _licenseValidUntil;

  String? _pendingRequestKey;
  String? _pendingKeySignature;

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _bookingService = widget.bookingService ?? BookingPaymentService();
    _storage = widget.storageService ?? SecureStorageService();

    final now = DateTime.now().add(const Duration(days: 1));
    _pickupAt = DateTime(now.year, now.month, now.day, 9, 0);
    _returnAt = _pickupAt.add(const Duration(days: 1));
    _licenseValidUntil = _returnAt.add(const Duration(days: 180));
    _vehicle = widget.initialVehicle;
    _loadDetail();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = _vehicle == null;
      _errorMessage = null;
    });

    try {
      final detail = await _discoveryService.getRentalDetail(widget.vehicleId);
      bool saved = false;
      if (await _storage.hasToken()) {
        try {
          final wl = await _discoveryService.getRentalWishlist();
          saved = wl.any((e) => e.id == widget.vehicleId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _vehicle = detail;
        _isWishlisted = saved;
        _isLoading = false;
      });
      await _calculateQuote();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load vehicle details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateQuote() async {
    setState(() {
      _isQuoting = true;
      _quoteError = null;
    });
    try {
      final quote = await _discoveryService.calculateRentalQuote(
        vehicleId: widget.vehicleId,
        pickupAt: _pickupAt,
        returnAt: _returnAt,
        quantity: _quantity,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _isQuoting = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isQuoting = false;
        _quote = null;
        _quoteError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isQuoting = false;
        _quote = null;
        _quoteError = 'Unable to check rental availability.';
      });
    }
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final range = await showDateRangePicker(
      context: context,
      firstDate: tomorrow,
      lastDate: tomorrow.add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _pickupAt, end: _returnAt),
    );
    if (range == null) return;
    final pickup = DateTime(range.start.year, range.start.month, range.start.day, 9, 0);
    final rawReturn = range.end.isAfter(range.start)
        ? range.end
        : range.start.add(const Duration(days: 1));
    final ret = DateTime(rawReturn.year, rawReturn.month, rawReturn.day, 9, 0);
    setState(() {
      _pickupAt = pickup;
      _returnAt = ret;
      if (_licenseValidUntil != null && _licenseValidUntil!.isBefore(ret)) {
        _licenseValidUntil = ret.add(const Duration(days: 30));
      }
      _bookingError = null;
    });
    await _calculateQuote();
  }

  Future<void> _toggleWishlist() async {
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('save rentals');
      return;
    }
    final next = !_isWishlisted;
    setState(() => _isWishlisted = next);
    try {
      await _discoveryService.setRentalWishlist(widget.vehicleId, save: next);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isWishlisted = !next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  Future<void> _bookRental() async {
    if (_isBooking || _quote == null || !_quote!.isAvailable) return;
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      _promptSignIn('book this rental');
      return;
    }

    final needsLicense =
        _vehicle?.requiresDrivingLicense == true || _quote!.requiresDrivingLicense;
    if (needsLicense && (!_licenseConfirmed || _licenseValidUntil == null)) {
      setState(() {
        _bookingError =
            'Motorcycle rentals require confirming a valid driving license through the return date.';
      });
      return;
    }

    final signature =
        '${widget.vehicleId}|${_pickupAt.toIso8601String()}|${_returnAt.toIso8601String()}|$_quantity|${_quote!.totalPrice}';
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
        listingId: widget.vehicleId,
        startsAt: _quote!.pickupAt,
        endsAt: _quote!.returnAt,
        quantity: _quantity,
        requestKey: _pendingRequestKey!,
        expectedTotal: _quote!.totalPrice,
        motorcycleLicenseConfirmed: needsLicense ? _licenseConfirmed : false,
        licenseValidUntil:
            needsLicense && _licenseValidUntil != null
                ? _formatDate(_licenseValidUntil!)
                : null,
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
            serviceTitle: _vehicle?.vehicleName ?? 'Rental Booking',
            summarySubtitle:
                '${_formatDate(_pickupAt)} → ${_formatDate(_returnAt)} (${_quote!.durationDays} day(s)) • $_quantity unit(s)',
          ),
        ),
      );
      await _calculateQuote();
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
            'Network error while booking rental. Tap Book Vehicle again to retry safely.';
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
        appBar: AppBar(title: const Text('Vehicle Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    if (_errorMessage != null || _vehicle == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Vehicle Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                Text(_errorMessage ?? 'Vehicle not found.'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final item = _vehicle!;
    final quote = _quote;
    final needsLicense = item.requiresDrivingLicense;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(item.vehicleName),
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
                imageUrl: item.primaryImageUrl,
                fallbackIcon: Icons.directions_bike_outlined,
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
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A4DF5),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatLkrAmount(item.pricePerDay)} / day',
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
                    item.vehicleName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.locationLabel}${item.transmission != null ? ' • ${item.transmission}' : ''}${item.providerBusinessName != null ? ' • ${item.providerBusinessName}' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (item.hasCoordinates) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => ArtisanLauncherService.showDirectionsModal(
                        context,
                        title: item.vehicleName,
                        latitude: item.latitude!,
                        longitude: item.longitude!,
                        address: item.pickupAddress,
                        city: item.locationLabel,
                      ),
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Pickup Directions'),
                    ),
                  ],
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      item.description!,
                      style: const TextStyle(fontSize: 14, height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Rental Dates & Quote Card
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
                          'Rental Dates & Quote',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDates,
                          icon: const Icon(Icons.date_range_outlined, size: 18),
                          label: Text(
                            '${_formatDate(_pickupAt)} → ${_formatDate(_returnAt)}',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Vehicles',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _quantity > 1
                                      ? () {
                                          setState(() => _quantity--);
                                          _calculateQuote();
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _quantity < 20
                                      ? () {
                                          setState(() => _quantity++);
                                          _calculateQuote();
                                        }
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isQuoting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          )
                        else if (_quoteError != null)
                          Text(
                            _quoteError!,
                            style: const TextStyle(color: AppTheme.errorRed),
                          )
                        else if (quote != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: quote.isAvailable
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote.isAvailable
                                      ? 'Available (${quote.availableQuantity} unit(s) free)'
                                      : 'Not enough units available (${quote.availableQuantity} free)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: quote.isAvailable
                                        ? AppTheme.successGreen
                                        : AppTheme.errorRed,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${quote.durationDays} day(s) • Total: ${formatLkrAmount(quote.totalPrice)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (needsLicense) ...[
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _licenseConfirmed,
                            onChanged: (val) => setState(
                              () => _licenseConfirmed = val ?? false,
                            ),
                            title: const Text(
                              'I hold a valid motorcycle driving license',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: _returnAt,
                                lastDate: _returnAt.add(const Duration(days: 3650)),
                                initialDate: _licenseValidUntil ??
                                    _returnAt.add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() => _licenseValidUntil = picked);
                              }
                            },
                            icon: const Icon(Icons.badge_outlined, size: 18),
                            label: Text(
                              'License Valid Until: ${_licenseValidUntil != null ? _formatDate(_licenseValidUntil!) : 'Select'}',
                            ),
                          ),
                        ],
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
                            key: const Key('rental_book_btn'),
                            onPressed: (_isBooking ||
                                    quote == null ||
                                    !quote.isAvailable)
                                ? null
                                : _bookRental,
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
                                    'Request Vehicle Rental',
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
