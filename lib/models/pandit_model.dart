class PanditModel {
  final String id;
  final String name;
  final String expertise;
  final double rating;
  final int basePrice;
  final String imageUrl;

  PanditModel({required this.id, required this.name, required this.expertise, required this.rating, required this.basePrice, required this.imageUrl});
  
  factory PanditModel.fromJson(Map<String, dynamic> json) => PanditModel(id: json['id'], name: json['name'], expertise: json['expertise'], rating: (json['rating'] as num).toDouble(), basePrice: json['base_price'], imageUrl: json['image_url']);
}
