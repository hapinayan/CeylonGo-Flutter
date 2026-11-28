import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/artisan_listing_model.dart';
import '../models/artisan_promotion_model.dart';
import '../models/artisan_reservation_model.dart';
import '../models/artisan_review_model.dart';
import '../models/artisan_wishlist_model.dart';
import '../models/showcase_item_model.dart';
import '../services/artisan_demo_service.dart';
import '../services/artisan_launcher_service.dart';
import '../services/artisan_service.dart';
import '../widgets/artisan_product_card.dart';
import '../widgets/featured_badge.dart';
import '../widgets/promotion_banner_card.dart';
import '../widgets/review_breakdown_widget.dart';
import '../widgets/star_rating_bar.dart';
import '../widgets/verification_badge.dart';
import 'artisan_product_detail_screen.dart';

class ArtisanBusinessDetailScreen extends StatefulWidget {
  final int listingId;
  final ArtisanService? artisanService;
  final SecureStorageService? storageService;

  const ArtisanBusinessDetailScreen({
    super.key,
    required this.listingId,
    this.artisanService,
    this.storageService,
  });

  @override
  State<ArtisanBusinessDetailScreen> createState() =>
      _ArtisanBusinessDetailScreenState();
}

class _ArtisanBusinessDetailScreenState
    extends State<ArtisanBusinessDetailScreen> {
  late final ArtisanService _artisanService;
  late final SecureStorageService _storageService;

  ArtisanListingResponse? _listing;
  List<ShowcaseItemSummary> _products = [];
  bool _isSavedToWishlist = false;
  List<ArtisanPromotionModel> _promotions = [];
  ArtisanReviewSummaryModel? _reviewSummary;
  List<ArtisanReviewModel> _reviews = [];
  int? _currentUserId;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _artisanService = widget.artisanService ??
        (ArtisanDemoService.isDemoMode
            ? ArtisanDemoService.instance
            : ArtisanService());
    _storageService = widget.storageService ?? SecureStorageService();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _storageService.getUser();
      _currentUserId = user != null ? int.tryParse(user.id) : null;

      final isDemo = ArtisanDemoService.isDemoMode;
      final futures = await Future.wait([
        _artisanService.getListingDetails(widget.listingId),
        _artisanService
            .getListingShowcaseItems(widget.listingId, pageSize: 20)
            .catchError(
              (_) => const ShowcaseItemPagination(
                items: [],
                total: 0,
                page: 1,
                pageSize: 20,
                totalPages: 0,
              ),
            ),
        _artisanService
            .checkWishlistStatus(widget.listingId)
            .catchError((_) => const ArtisanWishlistCheckModel(
                  listingId: 0,
                  isSaved: false,
                )),
        if (isDemo) ...[
          _artisanService
              .getActivePromotions(listingId: widget.listingId)
              .catchError((_) => const ArtisanPromotionPaginationModel(
                    items: [],
                    total: 0,
                    page: 1,
                    pageSize: 10,
                    totalPages: 0,
                  )),
          _artisanService
              .getListingReviewSummary(widget.listingId)
              .catchError((_) => ArtisanReviewSummaryModel(
                    listingId: widget.listingId,
                    listingTitle: '',
                    averageRating: 0.0,
                    totalReviews: 0,
                    ratingBreakdown: {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
                    verifiedReviewsCount: 0,
                  )),
          _artisanService
              .getListingReviews(widget.listingId, pageSize: 10)
              .catchError((_) => const ArtisanReviewPaginationModel(
                    items: [],
                    total: 0,
                    page: 1,
                    pageSize: 10,
                    totalPages: 0,
                    averageRating: 0.0,
                    totalReviews: 0,
                  )),
        ],
      ]);

      if (mounted) {
        setState(() {
          _listing = futures[0] as ArtisanListingResponse;
          final prodPagination = futures[1] as ShowcaseItemPagination;
          _products = prodPagination.items;
          final wishlistCheck = futures[2] as ArtisanWishlistCheckModel;
          _isSavedToWishlist = wishlistCheck.isSaved;
          if (isDemo && futures.length >= 6) {
            final promoPagination = futures[3] as ArtisanPromotionPaginationModel;
            _promotions = promoPagination.items;
            _reviewSummary = futures[4] as ArtisanReviewSummaryModel;
            final reviewPagination = futures[5] as ArtisanReviewPaginationModel;
            _reviews = reviewPagination.items;
          } else {
            _promotions = [];
            _reviewSummary = null;
            _reviews = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleWishlist() async {
    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      if (!mounted) return;
      _showLoginRequiredDialog('save workshops to your wishlist');
      return;
    }

    final currentlySaved = _isSavedToWishlist;
    setState(() {
      _isSavedToWishlist = !currentlySaved;
    });

    try {
      if (currentlySaved) {
        await _artisanService.removeFromWishlist(widget.listingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed workshop from wishlist.'),
              backgroundColor: AppTheme.primaryNavy,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _artisanService.addToWishlist(widget.listingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved workshop to your wishlist!'),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavedToWishlist = currentlySaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiError ? e.message : 'Wishlist update failed.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showLoginRequiredDialog(String actionDescription) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Login Required',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
        ),
        content: Text(
          'Please sign in to your CeylonGo traveler account to $actionDescription.',
          style: const TextStyle(color: AppTheme.textSecondary),
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

  Future<void> _handleWriteReview() async {
    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      _showLoginRequiredDialog('submit a review for this workshop');
      return;
    }

    try {
      final completedReservations = await _artisanService.getMyReservations(
        status: 'completed',
      );
      final eligible = completedReservations.where(
        (r) => r.artisanListingId == widget.listingId,
      ).toList();

      if (eligible.isEmpty) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.backgroundWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppTheme.accentOrange),
                SizedBox(width: 8),
                Text(
                  'Verified Review Policy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: const Text(
              'Reviews require a completed in-store reservation pickup. Once you collect your reserved handcrafted item from this workshop, you can share your verified review here.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
        return;
      }

      if (mounted) {
        _openReviewSubmissionModal(eligible.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiError ? e.message : 'Unable to verify review eligibility.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _openReviewSubmissionModal(ArtisanReservationModel reservation) {
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
                      'Verified in-store pickup booking #${reservation.id}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
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
                        hintText: 'e.g. Masterful woodcarving and hospitable family',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Feedback (Optional)',
                        hintText: 'Share your experience at the workshop...',
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
                                    widget.listingId,
                                    payload,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    _loadDetails();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Your verified review has been published.'),
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
                                'Submit Review',
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Artisan Workshop')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        ),
      );
    }

    if (_errorMessage != null || _listing == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Artisan Workshop')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                const Text(
                  'Failed to Load Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage ?? 'Listing not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadDetails,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final listing = _listing!;
    final coverUrl = listing.fullCoverImageUrl;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar with Cover Photo
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                key: const Key('wishlist_toggle_btn'),
                icon: Icon(
                  _isSavedToWishlist ? Icons.favorite : Icons.favorite_border,
                  color: _isSavedToWishlist ? AppTheme.errorRed : Colors.white,
                ),
                tooltip: _isSavedToWishlist ? 'Remove from Wishlist' : 'Add to Wishlist',
                onPressed: _toggleWishlist,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Share',
                onPressed: () {
                  final shareUrl = ArtisanLauncherService.buildPublicShareUrl(
                    'business',
                    listing.id,
                  );
                  ArtisanLauncherService.showShareModal(
                    context,
                    title: listing.title,
                    shareUrl: shareUrl,
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                listing.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Color(0xCC000000), blurRadius: 4)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildCoverPlaceholder(),
                    )
                  : _buildCoverPlaceholder(),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          listing.craftCategory,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      if (listing.isVerified) ...[
                        const SizedBox(width: 8),
                        VerificationBadge(isVerified: listing.isVerified),
                      ],
                      if (listing.isFeatured) ...[
                        const SizedBox(width: 8),
                        const FeaturedBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title & Provider Context
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  if (listing.providerBusinessName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Operated by ${listing.providerBusinessName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Contact & Direction Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ArtisanLauncherService.showContactModal(
                              context,
                              title: listing.title,
                              phone: listing.whatsappNumber ?? listing.phone,
                              email: listing.email,
                            );
                          },
                          icon: const Icon(Icons.contact_phone, size: 18),
                          label: const Text('Contact Seller'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (listing.hasCoordinates)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ArtisanLauncherService.showDirectionsModal(
                                context,
                                title: listing.title,
                                latitude: listing.latitude!,
                                longitude: listing.longitude!,
                                address: listing.address,
                                city: listing.city,
                              );
                            },
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text('Directions'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryNavy,
                              side: const BorderSide(color: AppTheme.primaryNavy),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Location and Address Card
                  Card(
                    elevation: 0,
                    color: AppTheme.backgroundWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppTheme.borderSlate),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, size: 18, color: AppTheme.accentOrange),
                              SizedBox(width: 6),
                              Text(
                                'Workshop Location',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (listing.address != null && listing.address!.isNotEmpty)
                            Text(
                              listing.address!,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          Text(
                            '${listing.city}, ${listing.district} District, Sri Lanka',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          if (listing.hasCoordinates) ...[
                            const SizedBox(height: 6),
                            Text(
                              'GPS: ${listing.latitude!.toStringAsFixed(4)}, ${listing.longitude!.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Artisan Story & Description
                  if (listing.description != null && listing.description!.isNotEmpty) ...[
                    const Text(
                      'Artisan Story & Craftsmanship',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Opening Hours Table
                  if (listing.businessHours.isNotEmpty) ...[
                    const Text(
                      'Opening Hours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: AppTheme.backgroundWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppTheme.borderSlate),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          children: listing.businessHours.map((h) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    h.dayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    h.formattedHours,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: h.isClosed ? AppTheme.errorRed : AppTheme.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Active Promotions Section
                  if (_promotions.isNotEmpty) ...[
                    const Text(
                      'Special Offers & Discounts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._promotions.map((p) => PromotionBannerCard(promotion: p)),
                    const SizedBox(height: 16),
                  ],

                  // Photo Gallery
                  if (listing.images.isNotEmpty) ...[
                    const Text(
                      'Workshop Gallery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: listing.images.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final img = listing.images[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 140,
                              child: Image.network(
                                img.fullImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: AppTheme.primarySubtle,
                                  child: const Icon(Icons.image, color: AppTheme.textMuted),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Product & Service Offerings Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Products & Experiences (${_products.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Products Grid
          if (_products.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: Text(
                    'No showcase products currently available for this workshop.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prod = _products[index];
                    return ArtisanProductCard(
                      product: prod,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtisanProductDetailScreen(
                              productId: prod.id,
                              artisanService: _artisanService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),

          // Reviews & Ratings Section (Demo preview only; excluded from Academic MVP)
          if (ArtisanDemoService.isDemoMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 32, color: AppTheme.borderSlate),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Traveler Reviews & Ratings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        ElevatedButton.icon(
                          key: const Key('write_review_btn'),
                          onPressed: _handleWriteReview,
                          icon: const Icon(Icons.rate_review_outlined, size: 16),
                          label: const Text('Write Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Aggregated Review Metrics
                    if (_reviewSummary != null)
                      ReviewBreakdownWidget(summary: _reviewSummary!),

                    const SizedBox(height: 16),

                    // Reviews List
                    if (_reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSlate),
                        ),
                        child: const Center(
                          child: Text(
                            'No traveler reviews submitted yet. Complete an in-store pickup to be the first to review!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ),
                      )
                    else
                      ..._reviews.map((r) => _buildReviewCard(r)),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ArtisanReviewModel r) {
    final dateStr =
        '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}';
    final isAuthor = _currentUserId != null && _currentUserId == r.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primarySubtle,
                    child: Text(
                      (r.userName != null && r.userName!.isNotEmpty)
                          ? r.userName![0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.userName ?? 'Verified Traveler',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  if (r.isVerifiedBooking) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, size: 14, color: AppTheme.successGreen),
                  ],
                ],
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StarRatingBar(rating: r.rating, size: 14),
          if (r.title != null && r.title!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.title!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
          ],
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              r.comment!,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          if (isAuthor) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _handleDeleteReview(r.id),
                  icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.errorRed),
                  label: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 11, color: AppTheme.errorRed),
                  ),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleDeleteReview(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _artisanService.deleteReview(id);
        _loadDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review deleted successfully.'),
              backgroundColor: AppTheme.primaryNavy,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is ApiError ? e.message : 'Failed to delete review.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: AppTheme.primaryNavy,
      child: const Center(
        child: Icon(Icons.storefront, size: 64, color: Colors.white54),
      ),
    );
  }
}
