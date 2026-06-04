class BookingModel {
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  final String id;
  final String userId;
  final String panditId;
  final DateTime date;
  final String status;
  final int amount;
  final String? paymentReference;

  BookingModel({
    required this.id,
    required this.userId,
    required this.panditId,
    required this.date,
    required this.status,
    required this.amount,
    this.paymentReference,
  });

  bool canTransitionTo(String nextStatus) {
    switch (status) {
      case statusPending:
        return nextStatus == statusConfirmed || nextStatus == statusCancelled;
      case statusConfirmed:
        return nextStatus == statusCompleted || nextStatus == statusCancelled;
      default:
        return false;
    }
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: (json['id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        panditId: (json['pandit_id'] ?? '').toString(),
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        status: (json['status'] ?? '').toString(),
        amount: ((json['amount'] ?? 0) as num).toInt(),
        paymentReference: json['payment_reference']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'pandit_id': panditId,
        'date': date.toIso8601String(),
        'status': status,
        'amount': amount,
        'payment_reference': paymentReference,
      };
}
