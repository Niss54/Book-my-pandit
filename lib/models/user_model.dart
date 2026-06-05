class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final String role;

  UserModel({
    required this.id, 
    required this.email, 
    required this.name, 
    this.profilePictureUrl,
    this.role = 'customer',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        name: (json['name'] ?? 'User').toString(),
        profilePictureUrl: json['profile_picture_url']?.toString(),
        role: (json['role'] ?? 'customer').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'profile_picture_url': profilePictureUrl,
        'role': role,
      };
}

