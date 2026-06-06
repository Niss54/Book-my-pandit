class ReviewModel {
  final String id;
  final String bookingId;
  final String userId;
  final String panditId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.panditId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: (json['id'] ?? '').toString(),
        bookingId: (json['booking_id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        panditId: (json['pandit_id'] ?? '').toString(),
        rating: ((json['rating'] ?? 0) as num).toInt(),
        comment: json['comment']?.toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'user_id': userId,
        'pandit_id': panditId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}
