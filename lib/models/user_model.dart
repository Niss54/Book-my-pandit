class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final String role;
  final String? phone;
  final String? address;

  UserModel({
    required this.id, 
    required this.email, 
    required this.name, 
    this.profilePictureUrl,
    this.role = 'customer',
    this.phone,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        name: (json['name'] ?? 'User').toString(),
        profilePictureUrl: json['profile_picture_url']?.toString(),
        role: (json['role'] ?? 'customer').toString(),
        phone: json['phone']?.toString(),
        address: json['address']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'profile_picture_url': profilePictureUrl,
        'role': role,
        'phone': phone,
        'address': address,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePictureUrl,
    String? role,
    String? phone,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}

