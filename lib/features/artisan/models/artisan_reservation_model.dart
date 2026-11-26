import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'artisan_listing_model.dart';

/// Supported lifecycle statuses for Artisan Product Reservations.
/// Strictly conforms to backend check constraint:
/// ['pending', 'confirmed', 'ready_for_pickup', 'completed', 'cancelled', 'expired'].
/// Note: 'rejected' is blocked pending Database Coordinator approval.
enum ReservationStatus {
  pending,
  confirmed,
  readyForPickup,
  completed,
  cancelled,
  expired;

  static ReservationStatus fromString(String? val) {
    switch (val?.trim().toLowerCase()) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'ready_for_pickup':
        return ReservationStatus.readyForPickup;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'expired':
        return ReservationStatus.expired;
      case 'pending':
      default:
        return ReservationStatus.pending;
    }
  }

  String get code {
    switch (this) {
      case ReservationStatus.confirmed:
        return 'confirmed';
      case ReservationStatus.readyForPickup:
        return 'ready_for_pickup';
      case ReservationStatus.completed:
        return 'completed';
      case ReservationStatus.cancelled:
        return 'cancelled';
      case ReservationStatus.expired:
        return 'expired';
      case ReservationStatus.pending:
        return 'pending';
    }
  }

  String get label {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending Approval';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.readyForPickup:
        return 'Ready for Pickup';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case ReservationStatus.pending:
        return const Color(0xFFD97706); // Amber
      case ReservationStatus.confirmed:
        return const Color(0xFF2563EB); // Blue
      case ReservationStatus.readyForPickup:
        return const Color(0xFF7C3AED); // Purple
      case ReservationStatus.completed:
        return AppTheme.successGreen; // Emerald
      case ReservationStatus.cancelled:
        return AppTheme.textMuted; // Slate
      case ReservationStatus.expired:
        return AppTheme.errorRed; // Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReservationStatus.pending:
        return const Color(0xFFFEF3C7);
      case ReservationStatus.confirmed:
        return const Color(0xFFDBEAFE);
      case ReservationStatus.readyForPickup:
        return const Color(0xFFEDE9FE);
      case ReservationStatus.completed:
        return const Color(0xFFD1FAE5);
      case ReservationStatus.cancelled:
        return const Color(0xFFF1F5F9);
      case ReservationStatus.expired:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icon {
    switch (this) {
      case ReservationStatus.pending:
        return Icons.hourglass_top_outlined;
      case ReservationStatus.confirmed:
        return Icons.check_circle_outline;
      case ReservationStatus.readyForPickup:
        return Icons.shopping_bag_outlined;
      case ReservationStatus.completed:
        return Icons.task_alt;
      case ReservationStatus.cancelled:
        return Icons.cancel_outlined;
      case ReservationStatus.expired:
        return Icons.event_busy_outlined;
    }
  }
}

/// Structured model for an Artisan Product Reservation response.
class ArtisanReservationModel {
  final int id;
  final int showcaseItemId;
  final int artisanListingId;
  final int travelerId;
  final int quantity;
  final double totalPrice;
  final String currency;
  final ReservationStatus status;
  final String? pickupDate;
  final String? specialNotes;
  final DateTime? expiresAt;
  final int? cancelledBy;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enriched presentation fields from backend
  final String? itemTitle;
  final String? itemImageUrl;
  final String? listingTitle;
  final String? providerBusinessName;
  final String? travelerName;
  final String? travelerEmail;

  const ArtisanReservationModel({
    required this.id,
    required this.showcaseItemId,
    required this.artisanListingId,
    required this.travelerId,
    required this.quantity,
    required this.totalPrice,
    required this.currency,
    required this.status,
    this.pickupDate,
    this.specialNotes,
    this.expiresAt,
    this.cancelledBy,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.itemTitle,
    this.itemImageUrl,
    this.listingTitle,
    this.providerBusinessName,
    this.travelerName,
    this.travelerEmail,
  });

  factory ArtisanReservationModel.fromJson(Map<String, dynamic> json) {
    return ArtisanReservationModel(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      showcaseItemId: json['showcase_item_id'] is int
          ? json['showcase_item_id'] as int
          : int.parse('${json['showcase_item_id']}'),
      artisanListingId: json['artisan_listing_id'] is int
          ? json['artisan_listing_id'] as int
          : int.parse('${json['artisan_listing_id']}'),
      travelerId: json['traveler_id'] is int
          ? json['traveler_id'] as int
          : int.parse('${json['traveler_id']}'),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 1,
      totalPrice: json['total_price'] != null
          ? double.tryParse('${json['total_price']}') ?? 0.0
          : 0.0,
      currency: json['currency']?.toString() ?? 'LKR',
      status: ReservationStatus.fromString(json['reservation_status']?.toString()),
      pickupDate: json['pickup_date']?.toString(),
      specialNotes: json['special_notes']?.toString(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      cancelledBy: json['cancelled_by'] != null
          ? int.tryParse('${json['cancelled_by']}')
          : null,
      cancellationReason: json['cancellation_reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      itemTitle: json['item_title']?.toString(),
      itemImageUrl: json['item_image_url']?.toString(),
      listingTitle: json['listing_title']?.toString(),
      providerBusinessName: json['provider_business_name']?.toString(),
      travelerName: json['traveler_name']?.toString(),
      travelerEmail: json['traveler_email']?.toString(),
    );
  }

  /// Whether the traveler or provider can cancel this reservation.
  bool get isCancellable =>
      status == ReservationStatus.pending ||
      status == ReservationStatus.confirmed ||
      status == ReservationStatus.readyForPickup;

  /// Whether the reservation is eligible for a review.
  bool get isEligibleForReview => status == ReservationStatus.completed;

  /// Resolved absolute image URL for the reserved product.
  String get fullItemImageUrl => resolveImageUrl(itemImageUrl);
}

/// Payload for creating a new product reservation.
class ArtisanReservationCreatePayload {
  final int showcaseItemId;
  final int quantity;
  final String pickupDate; // YYYY-MM-DD
  final String? specialNotes;

  const ArtisanReservationCreatePayload({
    required this.showcaseItemId,
    required this.quantity,
    required this.pickupDate,
    this.specialNotes,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'showcase_item_id': showcaseItemId,
      'quantity': quantity,
      'pickup_date': pickupDate,
    };
    if (specialNotes != null && specialNotes!.trim().isNotEmpty) {
      map['special_notes'] = specialNotes!.trim();
    }
    return map;
  }
}

/// Payload for cancelling an active reservation.
class ArtisanReservationCancelPayload {
  final String? cancellationReason;

  const ArtisanReservationCancelPayload({this.cancellationReason});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (cancellationReason != null && cancellationReason!.trim().isNotEmpty) {
      map['cancellation_reason'] = cancellationReason!.trim();
    }
    return map;
  }
}
