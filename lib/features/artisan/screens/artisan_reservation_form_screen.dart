import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/artisan_reservation_model.dart';
import '../models/showcase_item_model.dart';
import '../services/artisan_demo_service.dart';
import '../services/artisan_service.dart';
import '../widgets/stock_badge.dart';

/// Form screen for reserving an artisan product for in-store pickup and in-person payment.
/// Grounded in POST /api/v1/artisan-reservations.
class ArtisanReservationFormScreen extends StatefulWidget {
  final int? productId;
  final ShowcaseItemResponse? product;
  final ArtisanService? artisanService;
  final SecureStorageService? storageService;

  const ArtisanReservationFormScreen({
    super.key,
    this.productId,
    this.product,
    this.artisanService,
    this.storageService,
  });

  @override
  State<ArtisanReservationFormScreen> createState() =>
      _ArtisanReservationFormScreenState();
}

class _ArtisanReservationFormScreenState
    extends State<ArtisanReservationFormScreen> {
  late final ArtisanService _artisanService;
  late final SecureStorageService _storageService;

  ShowcaseItemResponse? _product;
  bool _isLoadingProduct = false;
  String? _productLoadError;

  int _quantity = 1;
  late DateTime _pickupDate;
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _submitError;
  ArtisanReservationModel? _createdReservation;

  @override
  void initState() {
    super.initState();
    _artisanService = widget.artisanService ??
        (ArtisanDemoService.isDemoMode
            ? ArtisanDemoService.instance
            : ArtisanService());
    _storageService = widget.storageService ?? SecureStorageService();

    // Default pickup date to tomorrow
    _pickupDate = DateTime.now().add(const Duration(days: 1));

    if (widget.product != null) {
      _product = widget.product;
    } else if (widget.productId != null) {
      _loadProductDetails(widget.productId!);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails(int id) async {
    setState(() {
      _isLoadingProduct = true;
      _productLoadError = null;
    });

    try {
      final res = await _artisanService.getShowcaseItemDetails(id);
      if (mounted) {
        setState(() {
          _product = res;
          _isLoadingProduct = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _productLoadError = e is ApiError ? e.message : 'Unable to load product';
          _isLoadingProduct = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate.isBefore(now) ? now : _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.accentOrange,
              onPrimary: Colors.white,
              onSurface: AppTheme.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _pickupDate = picked;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (_product == null) return;

    // Check authentication
    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final dateStr =
        '${_pickupDate.year}-${_pickupDate.month.toString().padLeft(2, '0')}-${_pickupDate.day.toString().padLeft(2, '0')}';

    final payload = ArtisanReservationCreatePayload(
      showcaseItemId: _product!.id,
      quantity: _quantity,
      pickupDate: dateStr,
      specialNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      final reservation = await _artisanService.createReservation(payload);
      if (mounted) {
        setState(() {
          _createdReservation = reservation;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e is ApiError ? e.message : e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Login Required',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        ),
        content: const Text(
          'Please sign in to your CeylonGo traveler account to reserve artisan handcrafted items for in-store pickup.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
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
              foregroundColor: AppTheme.backgroundWhite,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_createdReservation != null) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Reserve for Pickup'),
      ),
      body: _isLoadingProduct
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentOrange),
            )
          : _productLoadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                        const SizedBox(height: 12),
                        Text(
                          _productLoadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : _product == null
                  ? const Center(child: Text('No product found'))
                  : _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    final product = _product!;
    final maxAvailable = product.stockQuantity;
    final unitPrice = product.price ?? 0.0;
    final estimatedTotal = unitPrice * _quantity;
    final dateStr =
        '${_pickupDate.year}-${_pickupDate.month.toString().padLeft(2, '0')}-${_pickupDate.day.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Card Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSlate),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: product.fullImageUrl.isNotEmpty
                        ? Image.network(
                            product.fullImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: AppTheme.primarySubtle),
                          )
                        : Container(
                            color: AppTheme.primarySubtle,
                            child: const Icon(Icons.palette_outlined,
                                color: AppTheme.primaryNavy),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.listingTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.listingTitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${product.currency} ${unitPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const Spacer(),
                          StockBadge(
                            stockQuantity: product.stockQuantity,
                            isAvailable: product.isAvailable,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reservation Fields Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSlate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservation Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 14),

                // Quantity Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        Text(
                          'Reserve items for your visit',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _quantity > 1 ? AppTheme.primaryNavy : AppTheme.borderSlate,
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderSlate),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: _quantity < maxAvailable
                              ? AppTheme.primaryNavy
                              : AppTheme.borderSlate,
                          onPressed: _quantity < maxAvailable
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppTheme.borderSlate),

                // Pickup Date Picker
                const Text(
                  'Estimated Pickup Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderSlate),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: AppTheme.accentOrange),
                            const SizedBox(width: 10),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Change Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Special Notes Field
                const Text(
                  'Special Notes / Requests (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Gift wrapping preferences, expected arrival time, or custom requests...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total & Payment Notice Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSlate),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimated Total Price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${product.currency} ${estimatedTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.accentOrange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'In-store pickup only. No advance online payment is collected. Payment is completed in person (cash or card) directly with the artisan.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppTheme.errorRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting || maxAvailable == 0 ? null : _submitReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: AppTheme.backgroundWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Confirm In-Store Reservation',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final r = _createdReservation!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Reservation Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.successGreen,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reservation Placed Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reservation Reference: #${r.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentOrange,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Product', r.itemTitle ?? _product?.title ?? 'Item'),
                    const Divider(height: 16, color: AppTheme.borderSlate),
                    _buildReceiptRow('Workshop', r.listingTitle ?? _product?.listingTitle ?? 'Workshop'),
                    const Divider(height: 16, color: AppTheme.borderSlate),
                    _buildReceiptRow('Quantity', '${r.quantity}'),
                    const Divider(height: 16, color: AppTheme.borderSlate),
                    _buildReceiptRow('Estimated Total', '${r.currency} ${r.totalPrice.toStringAsFixed(0)}'),
                    const Divider(height: 16, color: AppTheme.borderSlate),
                    _buildReceiptRow('Pickup Date', r.pickupDate ?? 'Pending'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/artisan/reservations');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: AppTheme.backgroundWhite,
                  ),
                  child: const Text(
                    'View My Reservations',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Workshop'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
      ],
    );
  }
}
