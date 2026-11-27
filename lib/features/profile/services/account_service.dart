import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/models/user_model.dart';

class NotificationItemModel {
  final int id;
  final String notificationType;
  final String category;
  final String title;
  final String message;
  final String relatedEntityType;
  final int relatedEntityId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationItemModel({
    required this.id,
    required this.notificationType,
    required this.category,
    required this.title,
    required this.message,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      notificationType: json['notification_type']?.toString() ?? 'general',
      category: json['category']?.toString() ?? 'system',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      relatedEntityType: json['related_entity_type']?.toString() ?? '',
      relatedEntityId: json['related_entity_id'] is int
          ? json['related_entity_id'] as int
          : int.tryParse('${json['related_entity_id']}') ?? 0,
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
    );
  }

  NotificationItemModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationItemModel(
      id: id,
      notificationType: notificationType,
      category: category,
      title: title,
      message: message,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class NotificationPageModel {
  final int unreadCount;
  final List<NotificationItemModel> items;
  final int total;
  final int page;
  final int pageSize;

  const NotificationPageModel({
    required this.unreadCount,
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = <NotificationItemModel>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          items.add(NotificationItemModel.fromJson(item));
        }
      }
    }
    return NotificationPageModel(
      unreadCount: json['unread_count'] is int
          ? json['unread_count'] as int
          : int.tryParse('${json['unread_count']}') ?? 0,
      items: items,
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse('${json['total']}') ?? items.length,
      page: json['page'] is int
          ? json['page'] as int
          : int.tryParse('${json['page']}') ?? 1,
      pageSize: json['page_size'] is int
          ? json['page_size'] as int
          : int.tryParse('${json['page_size']}') ?? 20,
    );
  }
}

class TravelerPreferencesModel {
  final List<String> preferredDestinations;
  final List<String> interests;
  final List<String> accommodationPreferences;
  final List<String> transportPreferences;
  final int? budgetMin;
  final int? budgetMax;
  final String? travelStyle;

  const TravelerPreferencesModel({
    this.preferredDestinations = const [],
    this.interests = const [],
    this.accommodationPreferences = const [],
    this.transportPreferences = const [],
    this.budgetMin,
    this.budgetMax,
    this.travelStyle,
  });

  factory TravelerPreferencesModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic val) => val is List
        ? val.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const [];

    return TravelerPreferencesModel(
      preferredDestinations: strList(json['preferred_destinations']),
      interests: strList(json['interests']),
      accommodationPreferences: strList(json['accommodation_preferences']),
      transportPreferences: strList(json['transport_preferences']),
      budgetMin: json['budget_min'] is int
          ? json['budget_min'] as int
          : int.tryParse('${json['budget_min']}'),
      budgetMax: json['budget_max'] is int
          ? json['budget_max'] as int
          : int.tryParse('${json['budget_max']}'),
      travelStyle: json['travel_style']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'preferred_destinations': preferredDestinations,
        'interests': interests,
        'accommodation_preferences': accommodationPreferences,
        'transport_preferences': transportPreferences,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'travel_style': travelStyle,
      };
}

class NotificationSettingsModel {
  final bool bookingUpdates;
  final bool paymentUpdates;
  final bool communityActivity;
  final bool promotionalUpdates;

  const NotificationSettingsModel({
    this.bookingUpdates = true,
    this.paymentUpdates = true,
    this.communityActivity = true,
    this.promotionalUpdates = false,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      bookingUpdates: json['booking_updates'] != false,
      paymentUpdates: json['payment_updates'] != false,
      communityActivity: json['community_activity'] != false,
      promotionalUpdates: json['promotional_updates'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'booking_updates': bookingUpdates,
        'payment_updates': paymentUpdates,
        'community_activity': communityActivity,
        'promotional_updates': promotionalUpdates,
      };

  NotificationSettingsModel copyWith({
    bool? bookingUpdates,
    bool? paymentUpdates,
    bool? communityActivity,
    bool? promotionalUpdates,
  }) {
    return NotificationSettingsModel(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      paymentUpdates: paymentUpdates ?? this.paymentUpdates,
      communityActivity: communityActivity ?? this.communityActivity,
      promotionalUpdates: promotionalUpdates ?? this.promotionalUpdates,
    );
  }
}

/// Service connecting Traveler Profile, Preferences, Notification Settings & Notifications.
class AccountService {
  final ApiClient _api;
  final SecureStorageService _storage;

  AccountService({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  })  : _api = apiClient ?? ApiClient(),
        _storage = storageService ?? SecureStorageService();

  Future<UserModel> getProfile() async {
    final data = await _api.get(ApiConstants.meEndpoint);
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    await _storage.saveUser(user);
    return user;
  }

  Future<UserModel> updateProfile({
    required String fullName,
    String? phone,
    String? country,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
      'country':
          (country != null && country.trim().isNotEmpty) ? country.trim() : null,
    };
    final data = await _api.patch(ApiConstants.meEndpoint, body: payload);
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    await _storage.saveUser(user);
    return user;
  }

  Future<UserModel> deleteAvatar() async {
    final data = await _api.delete(ApiConstants.avatarEndpoint);
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    await _storage.saveUser(user);
    return user;
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final data = await _api.post(
      ApiConstants.changePasswordEndpoint,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? 'Password updated.';
    }
    return 'Password updated.';
  }

  Future<TravelerPreferencesModel> getPreferences() async {
    final data = await _api.get(ApiConstants.travelerPreferencesEndpoint);
    return TravelerPreferencesModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TravelerPreferencesModel> updatePreferences(
    TravelerPreferencesModel prefs,
  ) async {
    final data = await _api.put(
      ApiConstants.travelerPreferencesEndpoint,
      body: prefs.toJson(),
    );
    return TravelerPreferencesModel.fromJson(data as Map<String, dynamic>);
  }

  Future<NotificationSettingsModel> getNotificationSettings() async {
    final data =
        await _api.get(ApiConstants.travelerNotificationSettingsEndpoint);
    return NotificationSettingsModel.fromJson(data as Map<String, dynamic>);
  }

  Future<NotificationSettingsModel> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    final data = await _api.patch(
      ApiConstants.travelerNotificationSettingsEndpoint,
      body: settings.toJson(),
    );
    return NotificationSettingsModel.fromJson(data as Map<String, dynamic>);
  }

  Future<NotificationPageModel> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
    String? category,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (unreadOnly != null) 'unread_only': unreadOnly.toString(),
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final data = await _api.get(
      ApiConstants.notificationsEndpoint,
      queryParameters: params,
    );
    return NotificationPageModel.fromJson(data as Map<String, dynamic>);
  }

  Future<int> getUnreadCount() async {
    final data = await _api.get(ApiConstants.notificationsUnreadCountEndpoint);
    if (data is Map<String, dynamic>) {
      return data['unread_count'] is int
          ? data['unread_count'] as int
          : int.tryParse('${data['unread_count']}') ?? 0;
    }
    return 0;
  }

  Future<NotificationItemModel> markNotificationRead(int notificationId) async {
    final data =
        await _api.patch(ApiConstants.notificationReadEndpoint(notificationId));
    return NotificationItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<int> markAllNotificationsRead() async {
    final data = await _api.post(ApiConstants.notificationsReadAllEndpoint);
    if (data is Map<String, dynamic>) {
      return data['unread_count'] is int ? data['unread_count'] as int : 0;
    }
    return 0;
  }
}
