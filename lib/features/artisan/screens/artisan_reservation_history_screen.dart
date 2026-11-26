import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/artisan_reservation_model.dart';
import '../models/artisan_review_model.dart';
import '../services/artisan_demo_service.dart';
import '../services/artisan_service.dart';
import '../widgets/reservation_status_badge.dart';
import '../widgets/star_rating_bar.dart';

/// Screen displaying the traveler's product reservation history.
/// Conforms to GET /api/v1/artisan-reservations/me and POST /api/v1/artisan-reservations/{id}/cancel.
class ArtisanReservationHistoryScreen extends StatefulWidget {
  final ArtisanService? artisanService;
  final SecureStorageService? storageService;

  const ArtisanReservationHistoryScreen({
    super.key,
    this.artisanService,
    this.storageService,
  });

  @override
  State<ArtisanReservationHistoryScreen> createState() =>
      _ArtisanReservationHistoryScreenState();
}

class _ArtisanReservationHistoryScreenState
    extends State<ArtisanReservationHistoryScreen> {
  late final ArtisanService _artisanService;
  late final SecureStorageService _storageService;

  List<ArtisanReservationModel> _allReservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'active', 'completed', 'cancelled'

  @override
  void initState() {
    super.initState();
    _artisanService = widget.artisanService ??
        (ArtisanDemoService.isDemoMode
            ? ArtisanDemoService.instance
            : ArtisanService());
    _storageService = widget.storageService ?? SecureStorageService();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please sign in to view your reservations.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final list = await _artisanService.getMyReservations();
      if (mounted) {
        setState(() {
          _allReservations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiError ? e.message : 'Unable to load reservations';
          _isLoading = false;
        });
      }
    }
  }

  List<ArtisanReservationModel> get _filteredReservations {
    switch (_selectedFilter) {
      case 'active':
        return _allReservations.where((r) => r.isCancellable).toList();
      case 'completed':
        return _allReservations
            .where((r) => r.status == ReservationStatus.completed)
            .toList();
      case 'cancelled':
        return _allReservations
            .where((r) =>
                r.status == ReservationStatus.cancelled ||
                r.status == ReservationStatus.expired)
            .toList();
      case 'all':
      default:
        return _allReservations;
    }
  }

  Future<void> _handleCancel(ArtisanReservationModel reservation) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel reservation #${reservation.id} for "${reservation.itemTitle ?? 'this item'}"?',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation (optional)...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Reservation'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final updated = await _artisanService.cancelReservation(
          reservation.id,
          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
        );

        if (mounted) {
          setState(() {
            final idx = _allReservations.indexWhere((r) => r.id == reservation.id);
            if (idx != -1) {
              _allReservations[idx] = updated;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled successfully.'),
              backgroundColor: AppTheme.primaryNavy,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is ApiError ? e.message : 'Cancellation failed.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  void _openReviewModal(ArtisanReservationModel reservation) {
    double selectedRating = 5.0;
    final titleController = TextEditingController();
    final commentController = TextEditingController();
    bool isSubmitting = false;
    String? modalError;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Write a Review',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'For ${reservation.listingTitle ?? 'Artisan Workshop'} (Reservation #${reservation.id})',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Interactive Star Rating
                    Center(
                      child: Column(
                        children: [
                          StarRatingBar(
                            rating: selectedRating,
                            size: 32,
                            isInteractive: true,
                            onRatingChanged: (val) {
                              setModalState(() {
                                selectedRating = val;
                              });
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${selectedRating.toStringAsFixed(1)} Stars',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Headline (Optional)',
                        hintText: 'e.g. Masterful craftsmanship and friendly host',
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Experience (Optional)',
                        hintText: 'Share your in-store pickup experience and product quality...',
                      ),
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        modalError!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.errorRed),
                      ),
                    ],
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() {
                                  isSubmitting = true;
                                  modalError = null;
                                });

                                try {
                                  final payload = ArtisanReviewCreatePayload(
                                    reservationId: reservation.id,
                                    rating: selectedRating,
                                    title: titleController.text.trim().isEmpty
                                        ? null
                                        : titleController.text.trim(),
                                    comment: commentController.text.trim().isEmpty
                                        ? null
                                        : commentController.text.trim(),
                                  );

                                  await _artisanService.createReview(
                                    reservation.artisanListingId,
                                    payload,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Thank you! Your verified review has been published.'),
                                        backgroundColor: AppTheme.successGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    modalError = e is ApiError ? e.message : e.toString();
                                    isSubmitting = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Verified Review',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredReservations;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Product Reservations'),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: AppTheme.backgroundWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${_allReservations.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'active',
                    'Active (${_allReservations.where((r) => r.isCancellable).length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'completed',
                    'Completed (${_allReservations.where((r) => r.status == ReservationStatus.completed).length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'cancelled',
                    'Cancelled (${_allReservations.where((r) => r.status == ReservationStatus.cancelled || r.status == ReservationStatus.expired).length})',
                  ),
                ],
              ),
            ),
          ),

          // Main List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accentOrange),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: AppTheme.errorRed),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _loadReservations,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_note_outlined,
                                      size: 54, color: AppTheme.textMuted),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Reservations Found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Reserve handmade masks, pottery, textiles, or jewelry for in-store pickup.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/artisan');
                                    },
                                    child: const Text('Explore Artisan Workshops'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReservations,
                            color: AppTheme.accentOrange,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                return _buildReservationCard(list[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFFEF3C7),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF92400E) : AppTheme.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFFDE68A) : AppTheme.borderSlate,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = key;
        });
      },
    );
  }

  Widget _buildReservationCard(ArtisanReservationModel r) {
    return Card(
      elevation: 0,
      color: AppTheme.backgroundWhite,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSlate),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Reference & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation #${r.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                ReservationStatusBadge(status: r.status, isCompact: true),
              ],
            ),
            const Divider(height: 16, color: AppTheme.borderSlate),

            // Item and Workshop info
            Text(
              r.itemTitle ?? 'Handcrafted Item',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            if (r.listingTitle != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      r.listingTitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // Metadata Row: Quantity, Total, Pickup Date
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaCol('Quantity', '${r.quantity} pcs'),
                  _buildMetaCol('Total Price', '${r.currency} ${r.totalPrice.toStringAsFixed(0)}'),
                  _buildMetaCol('Pickup Date', r.pickupDate ?? 'Flexible'),
                ],
              ),
            ),

            if (r.cancellationReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cancellation Reason: ${r.cancellationReason}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.errorRed,
                ),
              ),
            ],

            // Action Buttons
            if (r.isCancellable || r.isEligibleForReview) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (r.isCancellable)
                    OutlinedButton.icon(
                      onPressed: () => _handleCancel(r),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel Reservation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (r.isEligibleForReview)
                    ElevatedButton.icon(
                      onPressed: () => _openReviewModal(r),
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Review Workshop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
      ],
    );
  }
}
