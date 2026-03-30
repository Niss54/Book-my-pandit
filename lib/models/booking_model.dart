class BookingModel {
  final String id;
  final String userId;
  final String panditId;
  final DateTime date;
  final String status;
  final int amount;

  BookingModel({required this.id, required this.userId, required this.panditId, required this.date, required this.status, required this.amount});

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(id: json['id'], userId: json['user_id'], panditId: json['pandit_id'], date: DateTime.parse(json['date']), status: json['status'], amount: json['amount']);
}
