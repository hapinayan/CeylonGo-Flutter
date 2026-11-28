import 'booking_item_model.dart';

/// CeylonGo Service Provider Dashboard View Data
/// Constructor-injected model ensuring zero hardcoded business info in production UI
class ProviderDashboardData {
  final String businessName;
  final String location;
  final int notificationCount;
  final List<BookingItemModel> todayBookings;
  final List<BookingItemModel> pendingRequests;
  final List<BookingItemModel> upcomingBookings;

  const ProviderDashboardData({
    required this.businessName,
    required this.location,
    this.notificationCount = 0,
    this.todayBookings = const [],
    this.pendingRequests = const [],
    this.upcomingBookings = const [],
  });

  /// Factory constructor providing clearly identified test fixture data
  factory ProviderDashboardData.fixture() {
    return const ProviderDashboardData(
      businessName: 'Galle Heritage Villa',
      location: 'Galle, Southern Province',
      notificationCount: 2,
      todayBookings: [
        BookingItemModel(
          id: 'bkg-001',
          guestName: 'Sarah Jenkins',
          serviceTitle: 'Deluxe Ocean View Villa',
          dateTimeDescription: 'Check-in Today, 2:00 PM • 2 Nights',
          status: 'confirmed',
          amount: 'LKR 45,000',
        ),
        BookingItemModel(
          id: 'bkg-002',
          guestName: 'David & Lisa Miller',
          serviceTitle: 'Traditional Cooking Experience',
          dateTimeDescription: 'Today, 5:30 PM • 2 Guests',
          status: 'confirmed',
          amount: 'LKR 16,000',
        ),
      ],
      pendingRequests: [
        BookingItemModel(
          id: 'bkg-003',
          guestName: 'Kumara Wickramasinghe',
          serviceTitle: 'Private Cinnamon Plantation Tour',
          dateTimeDescription: 'Requested for Tomorrow, 9:00 AM',
          status: 'pending',
          amount: 'LKR 22,500',
        ),
      ],
      upcomingBookings: [
        BookingItemModel(
          id: 'bkg-004',
          guestName: 'Elena Rostova',
          serviceTitle: 'Deluxe Ocean View Villa',
          dateTimeDescription: 'Nov 24 – Nov 27 • 3 Nights',
          status: 'upcoming',
          amount: 'LKR 67,500',
        ),
        BookingItemModel(
          id: 'bkg-005',
          guestName: 'Marcus Chen',
          serviceTitle: 'Southern Coastal Day Safari',
          dateTimeDescription: 'Nov 26, 7:00 AM • 4 Guests',
          status: 'upcoming',
          amount: 'LKR 38,000',
        ),
      ],
    );
  }

  /// Empty state instance
  factory ProviderDashboardData.empty() {
    return const ProviderDashboardData(
      businessName: '',
      location: '',
      notificationCount: 0,
      todayBookings: [],
      pendingRequests: [],
      upcomingBookings: [],
    );
  }
}
