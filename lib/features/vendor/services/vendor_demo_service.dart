import '../models/vendor_models.dart';

/// In-memory Demo Service for CeylonGo Vendor Portal.
/// All listings, bookings, and vendor registration/login demo actions
/// operate strictly in local memory without backend or database writes.
class VendorDemoService {
  VendorDemoService._() {
    resetToDefaults();
  }

  static final VendorDemoService instance = VendorDemoService._();

  static const VendorAccountDemo defaultDemoVendor = VendorAccountDemo(
    id: 'vnd-demo-001',
    businessName: 'Lanka Heritage Stays & Tours',
    email: 'vendor@ceylongo.com',
    phone: '+94 77 456 7890',
    category: VendorCategory.homestay,
    location: 'Kandy',
    isDemoSession: true,
  );

  VendorAccountDemo? _currentVendor;
  final List<VendorListing> _listings = [];
  final List<VendorBookingRequest> _bookings = [];
  final Map<String, Set<String>> _unavailableDatesByListing = {};
  final List<VendorReview> _reviews = [];
  final List<VendorNotificationItem> _notifications = [];

  VendorAccountDemo get currentVendor => _currentVendor ?? defaultDemoVendor;

  /// Returns only listings owned by the active demo vendor.
  /// Note: Client-side filtering is for demo data isolation only, not backend security.
  List<VendorListing> get listings => List.unmodifiable(
        _listings.where((l) => l.ownerVendorId == currentVendor.id),
      );
  List<VendorBookingRequest> get bookings => List.unmodifiable(_bookings);
  List<VendorReview> get reviews => List.unmodifiable(
        _reviews.where((r) => r.ownerVendorId == currentVendor.id),
      );
  List<VendorNotificationItem> get notifications => List.unmodifiable(
        _notifications.where((n) => n.ownerVendorId == currentVendor.id),
      );

  int get totalListingsCount => listings.length;
  int get activeListingsCount => listings.where((l) => l.isActive).length;
  int get totalBookingsCount => _bookings.length;
  int get pendingBookingsCount =>
      _bookings.where((b) => b.status == VendorBookingStatus.pending).length;

  void resetToDefaults() {
    _currentVendor = defaultDemoVendor;
    _listings
      ..clear()
      ..addAll([
        const VendorListing(
          id: 'vl_1',
          ownerVendorId: 'vnd-demo-001',
          title: 'Traditional Villa with garden',
          category: VendorCategory.homestay,
          location: 'Jaffna',
          priceLkr: 12500,
          description:
              'Heritage courtyard villa with traditional Sri Lankan breakfast and shaded verandah.',
          categorySpecificValue: '2 Rooms • 4 Guests • Wi-Fi, Breakfast',
          categoryDetails: {
            'rooms': '2',
            'max_guests': '4',
            'amenities': 'Wi-Fi, Breakfast',
          },
          imageUrl:
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          photos: [
            VendorListingPhoto(
              id: 'sample_vl_1',
              path:
                  'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
              isLocalFile: false,
            ),
          ],
          isActive: true,
        ),
        const VendorListing(
          id: 'vl_2',
          ownerVendorId: 'vnd-demo-001',
          title: 'Ella Rock Sunrise Hike',
          category: VendorCategory.activity,
          location: 'Ella',
          priceLkr: 4500,
          description:
              'Guided dawn trek along railway tracks and tea slopes to Ella Rock summit.',
          categorySpecificValue: '4 hours • 8 Max Participants',
          categoryDetails: {
            'duration': '4 hours',
            'max_participants': '8',
          },
          imageUrl:
              'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
          photos: [
            VendorListingPhoto(
              id: 'sample_vl_2',
              path:
                  'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
              isLocalFile: false,
            ),
          ],
          isActive: true,
        ),
        const VendorListing(
          id: 'vl_3',
          ownerVendorId: 'vnd-demo-001',
          title: 'Honda Dio 110cc Scooter',
          category: VendorCategory.rental,
          location: 'Kandy',
          priceLkr: 3200,
          description:
              'Reliable automatic scooter with 2 helmets for hill-country exploration.',
          categorySpecificValue: 'Automatic Scooter • Available daily',
          categoryDetails: {
            'vehicle_type': 'Automatic Scooter',
            'availability': 'Available daily',
          },
          imageUrl:
              'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=600',
          photos: [
            VendorListingPhoto(
              id: 'sample_vl_3',
              path:
                  'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=600',
              isLocalFile: false,
            ),
          ],
          isActive: false,
        ),
        // Separate sample vendor listing to ensure active vendor isolation.
        const VendorListing(
          id: 'vl_other_vendor',
          ownerVendorId: 'vnd-other-999',
          title: 'Unrelated Vendor Coastal Bungalow',
          category: VendorCategory.homestay,
          location: 'Mirissa',
          priceLkr: 18000,
          description: 'Belongs to another demo vendor and should stay hidden.',
          categorySpecificValue: '3 Rooms • 6 Guests',
          imageUrl: '',
          isActive: true,
        ),
      ]);

    _bookings
      ..clear()
      ..addAll([
        const VendorBookingRequest(
          id: 'vb_101',
          listingTitle: 'Traditional Villa with garden',
          customerName: 'Kamal Perera',
          customerEmail: 'kamal@ceylongo.com',
          customerPhone: '+94 71 234 5678',
          dateRange: '12 Dec – 14 Dec',
          unitsLabel: '2 Nights • 2 Guests',
          totalLkr: 25000,
          status: VendorBookingStatus.pending,
          notes: 'Early check-in around 11:00 AM if possible.',
        ),
        const VendorBookingRequest(
          id: 'vb_102',
          listingTitle: 'Ella Rock Sunrise Hike',
          customerName: 'Dilani Fernando',
          customerEmail: 'dilani@ceylongo.com',
          customerPhone: '+94 77 889 1122',
          dateRange: '16 Dec',
          unitsLabel: '3 Guests',
          totalLkr: 13500,
          status: VendorBookingStatus.accepted,
          notes: 'Meeting at Ella railway station.',
        ),
        const VendorBookingRequest(
          id: 'vb_103',
          listingTitle: 'Honda Dio 110cc Scooter',
          customerName: 'Nimal Silva',
          customerEmail: 'nimal@ceylongo.com',
          customerPhone: '+94 76 555 0199',
          dateRange: '05 Dec – 07 Dec',
          unitsLabel: '2 Days',
          totalLkr: 6400,
          status: VendorBookingStatus.completed,
          notes: 'Returned with full tank.',
        ),
        const VendorBookingRequest(
          id: 'vb_104',
          listingTitle: 'Traditional Villa with garden',
          customerName: 'Suresh Kumar',
          customerEmail: 'suresh@ceylongo.com',
          customerPhone: '+94 75 333 4455',
          dateRange: '20 Dec – 21 Dec',
          unitsLabel: '1 Night • 4 Guests',
          totalLkr: 12500,
          status: VendorBookingStatus.rejected,
          notes: 'Dates unavailable due to maintenance.',
        ),
      ]);

    final today = DateTime.now();
    String keyFor(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    _unavailableDatesByListing
      ..clear()
      ..addAll({
        'vl_1': {
          keyFor(today.add(const Duration(days: 3))),
          keyFor(today.add(const Duration(days: 4))),
        },
        'vl_2': {
          keyFor(today.add(const Duration(days: 6))),
        },
      });

    _reviews
      ..clear()
      ..addAll([
        const VendorReview(
          id: 'vr_1',
          ownerVendorId: 'vnd-demo-001',
          listingId: 'vl_1',
          listingTitle: 'Traditional Villa with garden',
          customerName: 'Amaya Jayawardena',
          rating: 5,
          dateLabel: '18 Nov 2026',
          comment:
              'Spotless rooms, peaceful courtyard garden, and warm Jaffna hospitality.',
        ),
        const VendorReview(
          id: 'vr_2',
          ownerVendorId: 'vnd-demo-001',
          listingId: 'vl_2',
          listingTitle: 'Ella Rock Sunrise Hike',
          customerName: 'Kasun Bandara',
          rating: 5,
          dateLabel: '11 Nov 2026',
          comment:
              'Great sunrise pace and clear safety briefing along the trail.',
        ),
        const VendorReview(
          id: 'vr_3',
          ownerVendorId: 'vnd-demo-001',
          listingId: 'vl_1',
          listingTitle: 'Traditional Villa with garden',
          customerName: 'Nadeesha Perera',
          rating: 4,
          dateLabel: '03 Nov 2026',
          comment:
              'Lovely breakfast and quiet location; Wi-Fi was slightly slow in the evening.',
        ),
        const VendorReview(
          id: 'vr_other',
          ownerVendorId: 'vnd-other-999',
          listingId: 'vl_other_vendor',
          listingTitle: 'Unrelated Vendor Coastal Bungalow',
          customerName: 'Ruwan Silva',
          rating: 3,
          dateLabel: '01 Nov 2026',
          comment: 'Sample review belonging to another vendor.',
        ),
      ]);

    _notifications
      ..clear()
      ..addAll([
        const VendorNotificationItem(
          id: 'vn_1',
          ownerVendorId: 'vnd-demo-001',
          type: VendorNotificationType.bookingRequest,
          title: 'New Booking Request',
          message:
              'Kamal Perera requested Traditional Villa with garden for 12 Dec – 14 Dec.',
          timeLabel: '10 mins ago',
          isRead: false,
        ),
        const VendorNotificationItem(
          id: 'vn_2',
          ownerVendorId: 'vnd-demo-001',
          type: VendorNotificationType.bookingStatus,
          title: 'Booking Accepted',
          message:
              'Ella Rock Sunrise Hike for Dilani Fernando (16 Dec) is marked Accepted in demo mode.',
          timeLabel: '2 hours ago',
          isRead: false,
        ),
        const VendorNotificationItem(
          id: 'vn_3',
          ownerVendorId: 'vnd-demo-001',
          type: VendorNotificationType.listingUpdate,
          title: 'Listing Photo Tips',
          message:
              'Add up to 5 local photos and choose a cover photo for higher visibility.',
          timeLabel: 'Yesterday',
          isRead: true,
        ),
        const VendorNotificationItem(
          id: 'vn_4',
          ownerVendorId: 'vnd-demo-001',
          type: VendorNotificationType.availabilityReminder,
          title: 'Availability Reminder',
          message:
              'Review your December holiday dates in Availability Calendar.',
          timeLabel: '2 days ago',
          isRead: false,
        ),
        const VendorNotificationItem(
          id: 'vn_5',
          ownerVendorId: 'vnd-demo-001',
          type: VendorNotificationType.announcement,
          title: 'CeylonGo Vendor Portal',
          message:
              'Welcome to the offline demo Vendor Portal. Changes stay in local memory.',
          timeLabel: '5 days ago',
          isRead: true,
        ),
      ]);
  }

  void registerVendorDemo({
    required String businessName,
    required String email,
    required String phone,
    required VendorCategory category,
    required String location,
  }) {
    _currentVendor = VendorAccountDemo(
      id: 'vnd-${DateTime.now().millisecondsSinceEpoch}',
      businessName: businessName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      category: category,
      location: location.trim(),
      isDemoSession: true,
    );
  }

  void signInDemoVendor() {
    _currentVendor = defaultDemoVendor;
  }

  Map<String, dynamic> toDemoSessionMap() {
    final vendor = currentVendor;
    return {
      'id': vendor.id,
      'business_name': vendor.businessName,
      'email': vendor.email,
      'phone': vendor.phone,
      'category': vendor.category.name,
      'location': vendor.location,
      'is_demo_session': true,
    };
  }

  void restoreDemoVendorFromMap(Map<String, dynamic> map) {
    final categoryName = map['category'] as String?;
    final category = VendorCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => defaultDemoVendor.category,
    );
    _currentVendor = VendorAccountDemo(
      id: (map['id'] as String?) ?? defaultDemoVendor.id,
      businessName:
          (map['business_name'] as String?) ?? defaultDemoVendor.businessName,
      email: (map['email'] as String?) ?? defaultDemoVendor.email,
      phone: (map['phone'] as String?) ?? defaultDemoVendor.phone,
      category: category,
      location: (map['location'] as String?) ?? defaultDemoVendor.location,
      isDemoSession: true,
    );
  }

  void setAuthenticatedVendor({
    required String id,
    required String businessName,
    required String email,
  }) {
    _currentVendor = VendorAccountDemo(
      id: id,
      businessName: businessName,
      email: email,
      phone: defaultDemoVendor.phone,
      category: VendorCategory.homestay,
      location: 'Sri Lanka',
      isDemoSession: false,
    );
  }

  void signOutVendor() {
    _currentVendor = null;
  }

  void addListing(VendorListing listing) {
    _listings.insert(0, listing);
  }

  void updateListing(VendorListing updated) {
    final idx = _listings.indexWhere((l) => l.id == updated.id);
    if (idx != -1) {
      _listings[idx] = updated;
    }
  }

  void toggleListingStatus(String id) {
    final idx = _listings.indexWhere((l) => l.id == id);
    if (idx != -1) {
      _listings[idx] = _listings[idx].copyWith(
        isActive: !_listings[idx].isActive,
      );
    }
  }

  void deleteListing(String id) {
    _listings.removeWhere((l) => l.id == id);
  }

  void updateBookingStatus(String id, VendorBookingStatus status) {
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(status: status);
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool isDateAvailable(String listingId, DateTime date) {
    final blocked = _unavailableDatesByListing[listingId];
    if (blocked == null) return true;
    return !blocked.contains(_dateKey(date));
  }

  void setDateAvailability(
    String listingId,
    DateTime date, {
    required bool available,
  }) {
    final set = _unavailableDatesByListing.putIfAbsent(listingId, () => {});
    final key = _dateKey(date);
    if (available) {
      set.remove(key);
    } else {
      set.add(key);
    }
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    }
  }

  void markAllNotificationsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].ownerVendorId == currentVendor.id &&
          !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }
}

