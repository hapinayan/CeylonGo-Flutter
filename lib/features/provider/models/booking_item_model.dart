/// CeylonGo Service Provider Booking Item Model
/// Represents individual booking entries across Today, Pending, and Upcoming sections
class BookingItemModel {
  final String id;
  final String guestName;
  final String serviceTitle;
  final String dateTimeDescription;
  final String status;
  final String? amount;

  const BookingItemModel({
    required this.id,
    required this.guestName,
    required this.serviceTitle,
    required this.dateTimeDescription,
    required this.status,
    this.amount,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    return BookingItemModel(
      id: json['id']?.toString() ?? '',
      guestName: json['guest_name'] as String? ?? 'Guest',
      serviceTitle: json['service_title'] as String? ?? 'Service',
      dateTimeDescription: json['date_time_description'] as String? ?? '',
      status: json['status'] as String? ?? 'confirmed',
      amount: json['amount'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_name': guestName,
      'service_title': serviceTitle,
      'date_time_description': dateTimeDescription,
      'status': status,
      if (amount != null) 'amount': amount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
