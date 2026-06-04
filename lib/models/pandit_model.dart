class PanditModel {
  final String id;
  final String name;
  final String expertise;
  final double rating;
  final int basePrice;
  final String imageUrl;

  PanditModel({required this.id, required this.name, required this.expertise, required this.rating, required this.basePrice, required this.imageUrl});
  
  factory PanditModel.fromJson(Map<String, dynamic> json) => PanditModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        expertise: (json['expertise'] ?? '').toString(),
        rating: ((json['rating'] ?? 0) as num).toDouble(),
        basePrice: ((json['base_price'] ?? 0) as num).toInt(),
        imageUrl: (json['image_url'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'expertise': expertise,
        'rating': rating,
        'base_price': basePrice,
        'image_url': imageUrl,
      };
}
